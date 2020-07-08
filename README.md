# sd2c

## Motivation

SSH Data Cloud Compute : simply execute a script on a cloud virtual machine

## Synopsis

This is a tool based on ssh-ec2 script. With one bash command,

## The latest version

Clone the git repository (see upper button)

## Installation

Go inside the directory and
```bash
$ make configure
$ conda activate sd2c
$ make docs
```

## Tests

To test the project
```bash
$ make test
```

To validate the typing
```bash
$ make typing
```
or to add type in code
```bash
$ make add-typing
```

To validate all the project
```bash
$ make validate
```

## Project Organization

    ├── Makefile              <- Makefile with commands like `make data` or `make train`
    ├── README.md             <- The top-level README for developers using this project.
    ├── data
    │   ├── external          <- Data from third party sources.
    │   ├── interim           <- Intermediate data that has been transformed.
    │   ├── processed         <- The final, canonical data sets for modeling.
    │   └── raw               <- The original, immutable data dump.
    │
    ├── docs                  <- A default Sphinx project; see sphinx-doc.org for details
    │
    ├── models                <- Trained and serialized models, model predictions, or model summaries
    │

    ├── references            <- Data dictionaries, manuals, and all other explanatory materials.
    │
    ├── reports               <- Generated analysis as HTML, PDF, LaTeX, etc.
    │   └── figures           <- Generated graphics and figures to be used in reporting
    │
    ├── setup.py              <- makes project pip installable (pip install -e .[tests])
    │                            so sources can be imported and dependencies installed
    ├── sd2c                <- Source code for use in this project
    │   ├── __init__.py       <- Makes src a Python module
    │   ├── build_dataset.py  <- Scripts to download or generate data
    │   ├── build_features.py <- Scripts to turn raw data into features for modeling
    │   ├── train_model.py    <- Scripts to train models and then use trained models to make predictions
    │   ├── evaluate_model.py <- Scripts to train models and then use trained models to make predictions
    │   ├── visualize.py      <- Scripts to create exploratory and results oriented visualizations
    │   ├── tools/__init__.py <- Python module to expose internal API
    │   └── tools/tools.py    <- Python module for functions, object, etc
    │
    └── tests                 <- Unit and integrations tests ((Mark directory as a sources root).


