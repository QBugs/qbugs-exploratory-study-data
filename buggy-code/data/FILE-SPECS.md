# Specifications of data files

## [buggy-code-data.csv](generated/buggy-code-data.csv)

- `project_full_name`: Full name of a GitHub project, i.e., organization + "/" + project-name
  * factor, e.g., "Qiskit/qiskit-ignis"

- `buggy_commit_hash`: git commit hash of the buggy source code
  * factor, e.g., "ec1b4ce759f1fb8ba0242dd6c4a309fa1b586666"

- `bug_id`: Bug id as original identified in the [Bugs in Quantum Computing Platforms: An Empirical Study](https://arxiv.org/abs/2110.14560)
  * factor: e.g., "1", "1909-5"

- `bug_type`: bug type
  * factor: "Classical" or "Quantum"

- `buggy_file_path`: relative path of the buggy file
  * factor, e.g., "qiskit_ignis/tomography/fitters/cvx_fit.py"

- `buggy_line_number`: line number of a buggy line
  * numerical

- `buggy_component`: buggy comment in `buggy_line_number` as described in the [Python's AST](https://docs.python.org/3/library/ast.html) documentation
  * factor, e.g., "Call", "Assignment", etc

Note that the same `buggy_line_number` in the same `buggy_file_path` of a `project_full_name`-`bug_id` bug could have more than one `buggy_component`.
