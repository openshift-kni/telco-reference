# Custom CRs
This directory is a placeholder for additional custom CRs which are
outside the scope of the reference CRs.

## Reference MCPs
The MCP CRs contained here are examples for a multi-mcp cluster and
are used to build policies which accelerate initial rollout of
configuration by increasing maxUnavailable and manipulating the MCP
pause. The MCPs should be created during initial cluster installation
in a paused state with maxUnavailable of 100%.
