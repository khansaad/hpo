# Hyperparameter Tuning

## Entrypoint

[`__main__.py`](./__main__.py) is the entrypoint for the ML module. Depending upon the value of `ml_algo_impl` received
from [`tunables.get_all_tunables`](./tunables.py), the appropriate hyperparameter optimization library module is called
to perform Bayesian Optimization.

Accepted values of `ml_algo_impl` are:
- `optuna_tpe`: Optuna with TPE (Tree-structured Parzen Estimator) sampler.
- `optuna_tpe_multivariate`: Optuna with multivariate TPE.
- `optuna_skopt`: Optuna with sampler using Scikit-Optimize as the backend.
- `hyperopt`: Hyperopt hyperparameter optimization library.

## Logging Level

The logging levels used in Python are <sup>[[1]]</sup>:

| Logging Level | Description                                                                                                                                                           |
|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `CRITICAL`    | A serious error, indicating that the program itself may be unable to continue running.                                                                                |
| `ERROR`       | Due to a more serious problem, the software has not been able to perform some function.                                                                               |
| `WARNING`     | An indication that something unexpected happened, or indicative of some problem in the near future (e.g. ‘disk space low’). The software is still working as expected.|
| `INFO`        | Confirmation that things are working as expected.                                                                                                                     |
| `DEBUG`       | Detailed information, typically of interest only when diagnosing problems.                                                                                            |
| `NOTSET`      | All messages are processed when the logger is the root logger, or delegation to the parent when the logger is a non-root logger.                                      |

By default, the logging level is set to `INFO` in [`logger.py`](./logger.py). To change the logging level, set the
`level` argument in `logging.basicConfig` function in [`logger.py`](./logger.py) to any of the above levels.

However, Optuna shows log messages at the `INFO` level by default. To suppress log messages of optuna, the logging level
for the Optuna’s root logger is set to `WARNING` by using `optuna.logging.set_verbosity()` in
[`bayes_optuna/optuna_hpo.py`](./bayes_optuna/optuna_hpo.py). To view log messages of optuna, the logging level can be
changed to `DEBUG` or `INFO` in [`bayes_optuna/optuna_hpo.py`](./bayes_optuna/optuna_hpo.py).

[1]: https://docs.python.org/3/howto/logging.html#when-to-use-logging

## Experiment Status

The status of the experiment run by the experiment manager for a config is set to one of `success`, `failure` or `prune`.

The criteria for setting the experiment status is:

| Experiment Status | Description                                                                   |
|-------------------|-------------------------------------------------------------------------------|
| `success`         | The experiment runs successfully without any error.                           |
| `failure`         | The experiment fails due to reason such as OOMKilled.                         |
| `prune`           | The experiment terminates due to reasons such as insufficient cpu and memory. |


## gRPC Client

[`grpc_client.py`](./grpc_client.py) is a command line client that allows users to interact with the gRPC service.

### Usage

```shell
$ python3 ./grpc_client.py 
Usage: grpc_client.py [OPTIONS] COMMAND [ARGS]...

  A HPO command line tool to allow interaction with HPO service

Options:
  --help  Show this message and exit.

Commands:
  config  Obtain a configuration set for a particular experiment trial
  count   Return a count of experiments currently running
  list    List names of all experiments currently running
  new     Create a new experiment
  next    Generate next configuration set for running experiment
  result  Update results for a particular experiment trial
  show    Show details of running experiment

```

Commands provide interactive input for params or allow users to set params on the command line for scripted use;

e.g.

```shell
$ python3 ./grpc_client.py new
 Experiment configuration file path: 
```

or

```shell
$ python3 ./grpc_client.py new --file=/tmp/hpo/newExperiment.json
```

> **_NOTE:_**  The default host and port for the client is `localhost` and `50051`.  If you wish to connect to a remote machine, or via a diferent port, please set the following environment variables, `HPO_HOST` and `HPO_PORT`. 
> e.g.
> ```shell
> $ export HPO_HOST=remoteMachine.com
> $ export HPO_PORT=9191
> ```