"""
    Base class for archive-specific component
    of the `OptimizationResults`.
"""
abstract ArchiveOutput

"""
    Base class for method-specific component
    of the `OptimizationResults`.
"""
abstract MethodOutput

immutable DummyMethodOutput <: MethodOutput end

# no method-specific output by default
Base.call(::Type{MethodOutput}, method::Optimizer) = DummyMethodOutput()

"""
  The results of running optimization method.

  Returned by `run!(oc::OptRunController)`.
  Should be compatible (on the API level) with the `Optim` package.
  See `make_opt_results()`.
"""
type OptimizationResults
  method::ASCIIString           # FIXME symbol instead or flexible?
  stop_reason::ASCIIString      # FIXME turn into type hierarchy of immutable reasons with their attached info
  iterations::Int
  start_time::Float64           # time (seconds) optimization started
  elasped_time::Float64         # time (seconds) optimization finished
  parameters::Parameters        # all user-specified parameters to bboptimize()
  f_calls::Int                  # total number of fitness function evaluations
  fit_scheme::FitnessScheme     # fitness scheme used by the archive
  archive_output::ArchiveOutput # archive-specific output
  method_output::MethodOutput   # method-specific output

  function OptimizationResults(ctrl, oc)
      new(
        string(oc.parameters[:Method]),
        stop_reason(ctrl),
        num_steps(ctrl),
        start_time(ctrl), elapsed_time(ctrl),
        oc.parameters,
        num_func_evals(ctrl),
        fitness_scheme(evaluator(ctrl).archive),
        ArchiveOutput(evaluator(ctrl).archive),
        MethodOutput(ctrl.optimizer))
  end
end

stop_reason(or::OptimizationResults) = or.stop_reason
iterations(or::OptimizationResults) = or.iterations
start_time(or::OptimizationResults) = or.start_time
elapsed_time(or::OptimizationResults) = or.elapsed_time
parameters(or::OptimizationResults) = or.parameters
f_calls(or::OptimizationResults) = or.f_calls

fitness_scheme(or::OptimizationResults) = or.fit_scheme
best_candidate(or::OptimizationResults) = or.archive_output.best_candidate
best_fitness(or::OptimizationResults) = or.archive_output.best_fitness
# FIXME doesn't work if there's no best candidate
numdims(or::OptimizationResults) = length(best_candidate(or))

# Alternative nomenclature that mimics Optim.jl more closely.
# FIXME should be it be enabled only for MinimizingFitnessScheme?
Base.minimum(or::OptimizationResults) = best_candidate(or)
f_minimum(or::OptimizationResults) = best_fitness(or)
# FIXME lookup stop_reason
iteration_converged(or::OptimizationResults) = iterations(or) >= parameters(or)[:MaxSteps]

"""
    `TopListArchive`-specific components of the optimization results.
"""
immutable TopListArchiveOutput{F,C} <: ArchiveOutput
  best_fitness::F
  best_candidate::C

  Base.call{F}(::Type{TopListArchiveOutput}, archive::TopListArchive{F}) =
    new{F,Individual}(best_fitness(archive), best_candidate(archive))
end

Base.call(::Type{ArchiveOutput}, archive::TopListArchive) = TopListArchiveOutput(archive)

"""
  `PopulationOptimizer`-specific components of the `OptimizationResults`.
  Stores the final population.
"""
immutable PopulationOptimizerOutput{P} <: MethodOutput
  population::P

  Base.call(::Type{PopulationOptimizerOutput}, method::PopulationOptimizer) =
    new{typeof(population(method))}(population(method))
end

Base.call(::Type{MethodOutput}, optimizer::PopulationOptimizer) = PopulationOptimizerOutput(optimizer)

population(or::OptimizationResults) = or.method_output.population
