# sd2c

## Motivation

SSH Data Cloud Compute : simply execute a script on a cloud virtual machine.

## Synopsis

This is a tool based on ssh-ec2 script. With one bash command, execute a script on a cloud provider (AWS, Azure, GCP) and get the result in your local directory

## Installation

Clone the git repository

## Prerequisites

- This code works for linux, if you don't have a linux subsystem, please install a WSL or or anything similar.

- You need Python 3 to be installed.


If you are not familiar with neither of the cloud provider available, it is suggested that you use AWS, wich is simpler to initialize.


To execute sd2c, you need credentials from the provider you execute your script on. You must at least have credentials for one provider.


- AWS:

1. You  need to create an AWS account, then IAM console -> Users -> User Actions -> Manage Access Keys-> Create Access Key

2. Store this pair of keys in 'HOME/.aws/credentials' as follows:

[default]\
aws_access_key_id = XXXXXXXXXXXXXXXXXXX\
aws_secret_access_key = XXXXXXXXXXXXXXXXXXX


- Azure

(Note that you can configure everything on https://portal.azure.com/)

1. Create an Application
az ad app create --display-name "<Your Application Display Name>" --password <Your_Password
                                                                                            
2. Create a Service principa
az ad sp create --id "<Application_Id>

3 . Assign role
az role assignment create --assignee "<Object_Id>" --role Owner --scope /subscriptions/{subscriptionId}

4. Create a file in /HOME/.azure/credentials.txt and store the credentials you created as follows:

[default]\
subscription_id=XXXXXXXXXXXXXXXXXXX\
client_id=XXXXXXXXXXXXXXXXXXX\
secret=XXXXXXXXXXXXXXXXXXX\
tenant=XXXXXXXXXXXXXXXXXX

- GCP

1. Create an account and create a project (you may need to ask your company authorizations to create one).

2. Create a file in /HOME/.azure/credentials.txt and store the credentials you created as follows:

[default]\
user_id = XXXXXXXXXXXXXXXXXXX\
key = XXXXXXXXXXXXXXXXXXX\
project = XXXXXXXXXXXXXXXXXXX\
datacenter = XXXXXXXXXXXXXXXXXXX

## Demos

To have a look at your instances on the provider
```bash
$ python -m sd2c --provider <provider> --status
```

To execute a script on a provider
```bash
$ python -m sd2c --provider <provider> '<your bash command>'
```

## Commands

| Description                                                                | Command                                                            |
|----------------------------------------------------------------------------|--------------------------------------------------------------------|
| Launch a sd2c, get the result back and terminate the instance              | `python -m sd2c --provider <provider>`                             |
| Launch a sd2c, get the result back and leave the instance alive            | `python -m sd2c --provider <provider> --leave`                     |
| Launch a sd2c on a multiplexer and let in run detached                     | `python -m sd2c --provider <provider> --detach`                    |
| Take a look at the multiplexer running                                     | `python -m sd2c --provider <provider> --attach`                    |
| Get the result of a detached instance and terminate the instance           | `python -m sd2c --provider <provider> --finish`                    |
| Get the result of a detached instance and leave the instance alive.        | `python -m sd2c --provider <provider> --finish --leave`            |
| Save an instance that should have been destroyed                           | In another terminal `python -m sd2c --provider <provider> --leave` |
| Force destruction of an instance                                           | `python -m sd2c --provider <provider> --destroy`                   |
| Have a look at the instances on the provider                               | `python -m sd2c --provider <provider> --status `                   |


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


