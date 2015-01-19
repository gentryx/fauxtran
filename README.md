# fauxtran
Simple, stupid Fortran to C++ translator for scientific applications.

Primary use case: transform kernels from scientific codes to run
within C++ libraries -- and enable compile time code generation. The
latter is important, as Fortran lacks such measures. Strictly speaking
even the C preprocessor is not available. And C++ class templates have
become an important vehicle to retrofit code with performance
optimizations. Examples include expression templates for vectorization
or compile time address calculation (for further reference see
http://dx.doi.org/10.1109/SC.Companion.2012.137 ).
