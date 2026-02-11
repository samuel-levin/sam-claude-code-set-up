# Browser Testing Skill

Use this skill to validate code changes in the browser before marking work complete.

## When to Use

After making code changes, before considering the work done.

## Instructions

1. **Understand what changed**
   - Identify the feature area, component, or functionality modified

2. **Check for existing guidance**
   - Look through the supporting .md files in this skill for relevant testing guidance
   - Check if the type of change has documented test procedures

3. **Check for related e2e tests**
   - See [e2e-test-mapping.md](e2e-test-mapping.md) for references to existing end-to-end tests
   - E2e tests show the expected flow
   - Read the test to understand the validation steps
   - Generalize the test steps for manual browser validation

4. **When no guidance exists**
   - Ask the user: "How should I validate [this change] in the browser?"
   - Follow their instructions
   - Use Playwright tools if appropriate (see [playwright-usage.md](playwright-usage.md))

5. **Report validation results**
   - What you tested
   - What you observed
   - Any issues or unexpected behavior

6. **Update the skill**
   - After receiving testing guidance, propose adding it to this skill
   - Suggest which file should be updated with the generalized testing information
   - Keep documentation focused on reusable patterns, not one-off validations
