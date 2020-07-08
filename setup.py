#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re
import subprocess
from typing import List

from setuptools import setup, find_packages

PYTHON_VERSION="3.6"

# USE_GPU="-gpu" ou "" si le PC possède une carte NVidia
# ou suivant la valeur de la variable d'environnement GPU (export GPU=yes)
USE_GPU: str = "-gpu" if (os.environ['GPU'].lower() in 'yes'
                     if "GPU" in os.environ
                     else os.path.isdir("/proc/driver/nvidia")
                          or "CUDA_PATH" in os.environ) else ""



# Run package dependencies
# FIXME Ajoutez et ajustez les dépendences nécessaire à l'exécution.
requirements: List[str] = [
    'click', 'click-pathlib',
    'python-dotenv',
    'PyInstaller',
    'apache-libcloud==2.8.0',
    'coloredlogs==14.0',
]

setup_requirements: List[str] = ["pytest-runner","setuptools_scm"]

# Package nécessaires aux tests
test_requirements: List[str] = [
    'pytest>=2.8.0',
    'pytest-openfiles', # For tests
    'pytest-xdist',
    'pytest-httpbin==0.0.7',
    'pytest-mock',

    'unittest2',
]

# Package nécessaires aux builds mais pas au run
# FIXME Ajoutez les dépendances nécessaire au build et au tests à ajuster suivant le projet
dev_requirements: List[str] = [
    'pip',
    # PPR necessaire a mlflow ? 'conda',
    'twine',  # To publish package in Pypi
    'sphinx', 'sphinx-execute-code', 'sphinx_rtd_theme', 'recommonmark', 'nbsphinx',  # To generate doc
    'flake8', 'pylint',  # For lint
]


# Return git remote url
def _git_url() -> str:
    try:
        with open(os.devnull, "wb") as devnull:
            out = subprocess.check_output(
                ["git", "remote", "get-url", "origin"],
                cwd=".",
                universal_newlines=True,
                stderr=devnull,
            )
        return out.strip()
    except subprocess.CalledProcessError:
        # git returned error, we are not in a git repo
        return ""
    except OSError:
        # git command not found, probably
        return ""


# Return Git remote in HTTP form
def _git_http_url() -> str:
    return re.sub(r".*@(.*):(.*).git", r"http://\1/\2", _git_url())

setup(
    name='sd2c' + USE_GPU,
    author="Octo Technology",
    author_email="bda@octo.com",
    description="SSH Data Cloud Compute : simply execute a script on a cloud virtual machine",
    long_description=open('README.md', mode='r', encoding='utf-8').read(),
    long_description_content_type='text/markdown',
    url=_git_http_url(),

    license='Apache License',
    keywords= "data science",
    classifiers=[  # See https://pypi.org/classifiers/
        'Development Status :: 2 - PRE-ALPHA',
        # Before release
        # 'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'License :: OSI Approved',
        'Natural Language :: English',
        'Programming Language :: Python :: '+ PYTHON_VERSION,
        'Operating System :: OS Independent',
        'Topic :: Scientific/Engineering :: Artificial Intelligence',
    ],
    python_requires='~=' + PYTHON_VERSION,
    test_suite="tests",
    setup_requires=setup_requirements,
    tests_require=test_requirements,
    extras_require={
        'dev': dev_requirements,
        'test': test_requirements,
        },
    packages=find_packages(),
    # TODO Declare the typing is correct ? (See PEP 561)
    # package_data={"sd2c": ["py.typed"]},
    use_scm_version=True,  # Manage versions from Git tags
    install_requires=requirements,
    entry_points={
           "console_scripts": [
               'sd2c = sd2c.__main__'
           ]
       },
)
