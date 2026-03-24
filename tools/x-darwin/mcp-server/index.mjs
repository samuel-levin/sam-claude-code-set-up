import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { readFileSync, writeFileSync, existsSync, unlinkSync } from "node:fs";

const execFileAsync = promisify(execFile);
const SCRIPTS_DIR = join(dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_CWD = "/Users/samuellevin/x-darwin";
const DEFAULT_CLIENT_ID = "d66b0704-1e05-4af1-bb6a-7da565b484fa";
const DEBUG_LOG = "/tmp/mantl-debug.log";
const DEBUG_MARKER = "/* __MANTL_DEBUG__ */";

async function runScript(script, args, cwd) {
  try {
    const { stdout, stderr } = await execFileAsync(
      "bash",
      [join(SCRIPTS_DIR, script), ...args],
      { timeout: 120_000, maxBuffer: 1024 * 1024, cwd: cwd || DEFAULT_CWD }
    );
    const output = [stdout, stderr].filter(Boolean).join("\n");
    return { content: [{ type: "text", text: output || "(no output)" }] };
  } catch (err) {
    const output = [err.stdout, err.stderr, err.message]
      .filter(Boolean)
      .join("\n");
    return {
      content: [{ type: "text", text: output }],
      isError: true,
    };
  }
}

async function ensureSandbox() {
  try {
    await execFileAsync("bash", [join(SCRIPTS_DIR, "docker", "setup-sandbox.sh")], {
      timeout: 30_000,
    });
  } catch (err) {
    // non-fatal — the docker run will fail with a clear error if sandbox is missing
  }
}

async function runDockerScript(script, args) {
  await ensureSandbox();
  try {
    const { stdout, stderr } = await execFileAsync(
      "docker",
      [
        "run", "--rm", "--network=llm-sandbox",
        "x-darwin-tools",
        `/tools/${script}`, ...args,
      ],
      { timeout: 120_000, maxBuffer: 1024 * 1024 }
    );
    const output = [stdout, stderr].filter(Boolean).join("\n");
    return { content: [{ type: "text", text: output || "(no output)" }] };
  } catch (err) {
    const output = [err.stdout, err.stderr, err.message]
      .filter(Boolean)
      .join("\n");
    return {
      content: [{ type: "text", text: output }],
      isError: true,
    };
  }
}

async function runKafkaCacheBust(clientId) {
  try {
    const { stdout, stderr } = await execFileAsync(
      "docker",
      [
        "exec", "-i", "broker", "kafka-console-producer.sh",
        "--bootstrap-server", "broker:29092",
        "--topic", "client.updates",
      ],
      {
        timeout: 15_000,
        maxBuffer: 1024 * 1024,
        input: JSON.stringify({ clientId }),
      }
    );
    const output = [stdout, stderr].filter(Boolean).join("\n");
    return {
      content: [{ type: "text", text: output || "Cache invalidation event sent" }],
    };
  } catch (err) {
    // kafka-console-producer writes to stderr even on success
    if (err.stdout || (err.stderr && !err.stderr.includes("ERROR"))) {
      return {
        content: [{ type: "text", text: "Cache invalidation event sent" }],
      };
    }
    return {
      content: [{ type: "text", text: `Kafka cache bust failed: ${err.message}` }],
      isError: true,
    };
  }
}

function removeInstrumentation(filePath) {
  const content = readFileSync(filePath, "utf8");
  const lines = content.split("\n");
  const filtered = lines.filter((line) => !line.includes(DEBUG_MARKER));
  const removed = lines.length - filtered.length;
  if (removed > 0) {
    writeFileSync(filePath, filtered.join("\n"), "utf8");
  }
  return removed;
}

const server = new McpServer({
  name: "x-darwin-tools",
  version: "1.0.0",
});

server.tool(
  "test",
  "Run tests for a MANTL service. Pass the service name and optionally a test file pattern. Special cases: web-automation uses console:e2e-dev (testcafe) with full path from service root (e.g. 'v3/console/tests/file.ts'); console-web uses test:unit.",
  {
    service: z.string().describe("Service name without @mantl/ prefix, e.g. 'console-api', 'web-automation'"),
    pattern: z.string().optional().describe("Test file pattern. For most services: 'some-file.spec'. For web-automation: full path like 'v3/console/tests/file.ts'"),
    cwd: z.string().optional().describe("Working directory (repo root or worktree). Defaults to /Users/samuellevin/x-darwin"),
  },
  async ({ service, pattern, cwd }) => {
    const args = [service];
    if (pattern) args.push(pattern);
    return runScript("test.sh", args, cwd);
  }
);

server.tool(
  "typecheck",
  "Run TypeScript type checking. Optionally scope to a specific service/package.",
  {
    service: z.string().optional().describe("Service name without @mantl/ prefix. Omit for full monorepo typecheck."),
    cwd: z.string().optional().describe("Working directory (repo root or worktree). Defaults to /Users/samuellevin/x-darwin"),
  },
  async ({ service, cwd }) => {
    const args = service ? [service] : [];
    return runScript("typecheck.sh", args, cwd);
  }
);

server.tool(
  "build",
  "Build a MANTL package or service using turbo.",
  {
    package: z.string().describe("Package name without @mantl/ prefix, e.g. 'client-config'"),
    cwd: z.string().optional().describe("Working directory (repo root or worktree). Defaults to /Users/samuellevin/x-darwin"),
  },
  async ({ package: pkg, cwd }) => {
    return runScript("build.sh", [pkg], cwd);
  }
);

server.tool(
  "update_client_config",
  "Apply a partial update to a client config. Reads the current config from the database, deep merges the provided JSON partial into it, writes it back, and fires a Kafka cache invalidation event. DB operations run in an isolated Docker container (llm-sandbox network) that can only reach the dev Postgres.",
  {
    client_id: z.string().optional().describe("The client UUID. Defaults to d66b0704-1e05-4af1-bb6a-7da565b484fa"),
    update: z.string().describe("JSON string to deep merge into the existing client config, e.g. '{\"products\":{\"legacySavings\":{\"name\":\"New Name\"}}}'"),
  },
  async ({ client_id, update }) => {
    const resolvedClientId = client_id || DEFAULT_CLIENT_ID;
    // DB operations run in sandboxed Docker container (can only reach dev Postgres)
    const dbResult = await runDockerScript(
      "update_client_config.sh",
      [resolvedClientId, update]
    );

    if (dbResult.isError) return dbResult;

    // Kafka cache bust runs on host (broker only listens on tooling_default interface)
    const kafkaResult = await runKafkaCacheBust(resolvedClientId);

    const dbText = dbResult.content[0].text;
    const kafkaText = kafkaResult.content[0].text;
    return {
      content: [{ type: "text", text: `${dbText}\n${kafkaText}` }],
      isError: kafkaResult.isError,
    };
  }
);

server.tool(
  "read_client_config",
  "Read a client's config (or a section of it) from the database. Returns JSON. Use a jq query to extract specific sections, e.g. '.services.beneficiaryWithSignatures' or '.products.consumerChecking.optionalServiceIds'. DB operations run in an isolated Docker container.",
  {
    client_id: z.string().optional().describe("The client UUID. Defaults to d66b0704-1e05-4af1-bb6a-7da565b484fa"),
    query: z.string().optional().describe("jq query to extract a section of the config, e.g. '.services' or '.products.consumerChecking'. Defaults to '.' (full config)"),
  },
  async ({ client_id, query }) => {
    return runDockerScript("read_client_config.sh", [client_id || DEFAULT_CLIENT_ID, query || "."]);
  }
);

server.tool(
  "read_application",
  "Read an application from the database. By default returns the most recently created application. Use a jq query to extract specific fields, e.g. '.status', '.fields', '.required_actions'. The application table is application_service.application.",
  {
    id: z.string().optional().describe("Application UUID. If omitted, returns the most recently created application."),
    query: z.string().optional().describe("jq query to extract fields, e.g. '.status' or '{id, status, type, required_actions}'. Defaults to '.' (full row)"),
  },
  async ({ id, query }) => {
    const args = [id || "", query || "."];
    return runDockerScript("read_application.sh", args);
  }
);

server.tool(
  "restart",
  "Restart a MANTL microservice by running its dev command.",
  {
    service: z.string().describe("Service name without @mantl/ prefix, e.g. 'console-api'"),
    cwd: z.string().optional().describe("Working directory (repo root or worktree). Defaults to /Users/samuellevin/x-darwin"),
  },
  async ({ service, cwd }) => {
    return runScript("restart.sh", [service], cwd);
  }
);

server.tool(
  "instrument",
  "Inject a temporary debug logging line into a source file. The line captures the given expressions and appends JSON to /tmp/mantl-debug.log at runtime. Use `read_debug_log` to read captured output and `deinstrument` to clean up.",
  {
    file: z.string().describe("Absolute path to the source file to instrument"),
    line: z.number().describe("Line number to insert the debug statement BEFORE (1-indexed)"),
    expressions: z.string().describe("Comma-separated variable/expression names to capture, e.g. 'applicationId, executionSteps'"),
  },
  async ({ file, line, expressions }) => {
    try {
      const content = readFileSync(file, "utf8");
      const lines = content.split("\n");
      if (line < 1 || line > lines.length + 1) {
        return {
          content: [{ type: "text", text: `Line ${line} out of range (file has ${lines.length} lines)` }],
          isError: true,
        };
      }

      // Match indentation from the target line
      const targetLine = lines[line - 1] || "";
      const indent = targetLine.match(/^(\s*)/)[1];

      // Short file path: last 3 segments
      const shortFile = file.split("/").slice(-3).join("/");

      // Build the data object from expressions
      const exprs = expressions.split(",").map((e) => e.trim()).filter(Boolean);
      const dataObj = exprs.join(", ");

      const debugLine = `${indent}${DEBUG_MARKER} require('fs').appendFileSync('${DEBUG_LOG}', JSON.stringify({ ts: new Date().toISOString(), file: '${shortFile}', line: ${line}, data: { ${dataObj} } }) + '\\n');`;

      lines.splice(line - 1, 0, debugLine);
      writeFileSync(file, lines.join("\n"), "utf8");

      return {
        content: [{ type: "text", text: `Instrumented ${shortFile}:${line} — capturing: ${exprs.join(", ")}` }],
      };
    } catch (err) {
      return {
        content: [{ type: "text", text: `Failed to instrument: ${err.message}` }],
        isError: true,
      };
    }
  }
);

server.tool(
  "deinstrument",
  "Remove all debug instrumentation injected by `instrument`. Cleans debug marker lines from source files and deletes /tmp/mantl-debug.log.",
  {
    file: z.string().optional().describe("Specific file to clean. If omitted, searches all files under cwd/src for instrumentation."),
    cwd: z.string().optional().describe("Repo root for searching. Defaults to /Users/samuellevin/x-darwin"),
  },
  async ({ file, cwd }) => {
    try {
      const results = [];

      // Delete the debug log
      if (existsSync(DEBUG_LOG)) {
        unlinkSync(DEBUG_LOG);
        results.push("Deleted " + DEBUG_LOG);
      }

      if (file) {
        // Clean a specific file
        const removed = removeInstrumentation(file);
        results.push(removed > 0 ? `Removed ${removed} debug line(s) from ${file}` : `No instrumentation found in ${file}`);
      } else {
        // Search for all instrumented files
        const searchDir = (cwd || DEFAULT_CWD) + "/src";
        try {
          const { stdout } = await execFileAsync("grep", ["-rl", DEBUG_MARKER, searchDir], { timeout: 10_000 });
          const files = stdout.trim().split("\n").filter(Boolean);
          for (const f of files) {
            const removed = removeInstrumentation(f);
            if (removed > 0) results.push(`Removed ${removed} debug line(s) from ${f}`);
          }
          if (files.length === 0) results.push("No instrumented files found");
        } catch (grepErr) {
          // grep returns exit code 1 when no matches found
          if (grepErr.code === 1 || (grepErr.status === 1)) {
            results.push("No instrumented files found");
          } else {
            results.push(`Search error: ${grepErr.message}`);
          }
        }
      }

      return {
        content: [{ type: "text", text: results.join("\n") }],
      };
    } catch (err) {
      return {
        content: [{ type: "text", text: `Failed to deinstrument: ${err.message}` }],
        isError: true,
      };
    }
  }
);

server.tool(
  "read_debug_log",
  "Read captured debug output from /tmp/mantl-debug.log (written by `instrument`-injected lines). Returns pretty-printed JSON entries.",
  {
    clear: z.boolean().optional().describe("Delete the log file after reading"),
    tail: z.number().optional().describe("Only return the last N entries"),
    filter: z.string().optional().describe("Only return entries containing this substring"),
  },
  async ({ clear, tail, filter }) => {
    try {
      if (!existsSync(DEBUG_LOG)) {
        return {
          content: [{ type: "text", text: "No debug log found at " + DEBUG_LOG }],
        };
      }

      const raw = readFileSync(DEBUG_LOG, "utf8").trim();
      if (!raw) {
        return {
          content: [{ type: "text", text: "Debug log is empty" }],
        };
      }

      let entries = raw.split("\n");

      if (filter) {
        entries = entries.filter((e) => e.includes(filter));
      }

      if (tail && tail > 0) {
        entries = entries.slice(-tail);
      }

      // Pretty-print each JSON entry
      const formatted = entries.map((e) => {
        try {
          return JSON.stringify(JSON.parse(e), null, 2);
        } catch {
          return e;
        }
      });

      const output = `${entries.length} entries:\n\n${formatted.join("\n\n")}`;

      if (clear) {
        unlinkSync(DEBUG_LOG);
      }

      return {
        content: [{ type: "text", text: output }],
      };
    } catch (err) {
      return {
        content: [{ type: "text", text: `Failed to read debug log: ${err.message}` }],
        isError: true,
      };
    }
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
