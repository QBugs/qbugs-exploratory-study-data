# ------------------------------------------------------------------------------
# A set of utility functions for 'subjects'.
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

set_programming_languages <- function(df) {
  df$'languages' <- NA
  df$'languages'[df$'project_full_name' == 'PennyLaneAI/pennylane']        <- 'Python'
  df$'languages'[df$'project_full_name' == 'ProjectQ-Framework/ProjectQ']  <- 'C++ Python'
  df$'languages'[df$'project_full_name' == 'QE-Lab/OpenQL']                <- 'C++ Python'
  df$'languages'[df$'project_full_name' == 'Qiskit/qiskit-aer']            <- 'Python'
  df$'languages'[df$'project_full_name' == 'Qiskit/qiskit-ignis']          <- 'Python'
  df$'languages'[df$'project_full_name' == 'Qiskit/qiskit-terra']          <- 'Python'
  df$'languages'[df$'project_full_name' == 'aspuru-guzik-group/tequila']   <- 'Python'
  df$'languages'[df$'project_full_name' == 'aws/amazon-braket-sdk-python'] <- 'Python'
  df$'languages'[df$'project_full_name' == 'dwavesystems/dwave-system']    <- 'Python'
  df$'languages'[df$'project_full_name' == 'eclipse/xacc']                 <- 'C++ C Python'
  df$'languages'[df$'project_full_name' == 'microsoft/QuantumLibraries']   <- 'Q# C#'
  df$'languages'[df$'project_full_name' == 'microsoft/qsharp-compiler']    <- 'C# F# Q#'
  df$'languages'[df$'project_full_name' == 'microsoft/qsharp-runtime']     <- 'C# C++ Q#'
  df$'languages'[df$'project_full_name' == 'quantumlib/Cirq']              <- 'Python'
  df$'languages'[df$'project_full_name' == 'qulacs/qulacs']                <- 'C++ C'
  df$'languages'[df$'project_full_name' == 'rigetti/pyquil']               <- 'Python'
  df$'languages'[df$'project_full_name' == 'unitaryfund/mitiq']            <- 'Python'
  df$'languages'[df$'project_full_name' == 'xanaduai/strawberryfields']    <- 'Python'
  return(df)
}

# EOF
