# Specifications of data files

## [`data/generated/bugs-in-quantum-computing-platforms.csv`](data/generated/bugs-in-quantum-computing-platforms.csv)

- `id`: Bug id as original identified in the [Bugs in Quantum Computing Platforms: An Empirical Study](https://arxiv.org/abs/2110.14560)
  * factor: e.g., "1", "1909-5"

- `type`: Whether the bug has occurred in classical or quantum code
  * factor: "Classical" or "Quantum"

- `project_full_name`: full name of a GitHub project, i.e., organization + "/" + project-name 
  * factor: e.g., Qiskit/qiskit-aer

- `project_clone_url`: URL to the project's repository
  * factor: e.g., https://github.com/Qiskit/qiskit-aer.git

- `fix_commit_hash`: Fix commit's hash
  * factor: e.g., 48498dd0edc4e1ed1ee4bb287edd89541af104b2

- `component`: Abstract buggy component involved in the fix
  * factor: e.g., "Quantum Abstractions, Simulator"

- `symptom`: Brief description of bug's symptom
  * factor: e.g., "Incorrect Final Measurement, Incorrect Output"

- `bug_pattern`: Brief description of bug's pattern
  * factor: e.g., "Overlooked Corner Case"

- `complexity`: Complexity of the bug
  * factor: e.g., "1", "100+"
