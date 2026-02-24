import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const execFileAsync = promisify(execFile);
const SCRIPTS_DIR = join(dirname(fileURLToPath(import.meta.url)), "..");

async function runScript(script, args) {
  try {
    const { stdout, stderr } = await execFileAsync(
      "bash",
      [join(SCRIPTS_DIR, script), ...args],
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

const server = new McpServer({
  name: "x-darwin-tools",
  version: "1.0.0",
});

server.tool(
  "test",
  "Run tests for a MANTL service. Pass the service name and optionally a test file pattern. For web-automation, uses console:e2e-dev (testcafe) and the pattern must be a full path from the service root (e.g. 'v3/console/tests/file.ts').",
  {
    service: z.string().describe("Service name without @mantl/ prefix, e.g. 'console-api', 'web-automation'"),
    pattern: z.string().optional().describe("Test file pattern. For most services: 'some-file.spec'. For web-automation: full path like 'v3/console/tests/file.ts'"),
  },
  async ({ service, pattern }) => {
    const args = [service];
    if (pattern) args.push(pattern);
    return runScript("test.sh", args);
  }
);

server.tool(
  "typecheck",
  "Run TypeScript type checking. Optionally scope to a specific service/package.",
  {
    service: z.string().optional().describe("Service name without @mantl/ prefix. Omit for full monorepo typecheck."),
  },
  async ({ service }) => {
    const args = service ? [service] : [];
    return runScript("typecheck.sh", args);
  }
);

server.tool(
  "build",
  "Build a MANTL package or service using turbo.",
  {
    package: z.string().describe("Package name without @mantl/ prefix, e.g. 'client-config'"),
  },
  async ({ package: pkg }) => {
    return runScript("build.sh", [pkg]);
  }
);

server.tool(
  "update_client_config",
  "Apply a partial update to a client config. Reads the current config from the database, deep merges the provided JSON partial into it, writes it back, and fires a Kafka cache invalidation event.",
  {
    client_id: z.string().describe("The client UUID"),
    update: z.string().describe("JSON string to deep merge into the existing client config, e.g. '{\"products\":{\"legacySavings\":{\"name\":\"New Name\"}}}'"),
  },
  async ({ client_id, update }) => {
    return runScript("update_client_config.sh", [client_id, update]);
  }
);

server.tool(
  "restart",
  "Restart a MANTL microservice by running its dev command.",
  {
    service: z.string().describe("Service name without @mantl/ prefix, e.g. 'console-api'"),
  },
  async ({ service }) => {
    return runScript("restart.sh", [service]);
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
