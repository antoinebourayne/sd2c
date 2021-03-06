#!/usr/bin/env make

# SNIPPET Le shebang précédant permet de creer des alias des cibles du Makefile.
# Il faut que le Makefile soit executable
# 	chmod u+x Makefile
# 	git update-index --chmod=+x Makefile
# Puis, par exemple
# 	ln -s Makefile configure
# 	ln -s Makefile test
# 	ln -s Makefile train
# 	./configure		# Execute make configure
# 	./test 			# Execute make test
#   ./train 		# Train the model
# Attention, il n'est pas possible de passer les paramètres aux scripts

# ---------------------------------------------------------------------------------------
# SNIPPET pour changer le mode de gestion du Makefile.
# Avec ces trois paramètres, toutes les lignes d'une recette sont invoquées dans le même shell.
# Ainsi, il n'est pas nécessaire d'ajouter des '&&' ou des '\' pour regrouper les lignes.
# Comme Make affiche l'intégralité du block de la recette avant de l'exécuter, il n'est
# pas toujours facile de savoir quel est la ligne en échec.
# Je vous conseille dans ce cas d'ajouter au début de la recette 'set -x'
# Attention : il faut une version > 4 de  `make` (`make -v`).
# Les versions CentOS d'Amazone ont une version 3.82.
# Utilisez `conda install -n $(VENV_AWS) make>=4 -y`
# WARNING: Use make >4.0
SHELL=/bin/bash
.SHELLFLAGS = -e -c
.ONESHELL:

# ---------------------------------------------------------------------------------------
# SNIPPET pour détecter l'OS d'exécution.
ifeq ($(OS),Windows_NT)
    OS := Windows
    EXE:=.exe
    SUDO?=
else
    OS := $(shell sh -c 'uname 2>/dev/null || echo Unknown')
    EXE:=
    SUDO?=
endif


# ---------------------------------------------------------------------------------------
# SNIPPET pour détecter la présence d'un GPU afin de modifier le nom du projet
# et ses dépendances si nécessaire.
ifdef GPU
USE_GPU:=$(shell [[ "$$GPU" == yes ]] && echo "-gpu")
else ifneq ("$(wildcard /proc/driver/nvidia)","")
USE_GPU:=-gpu
else ifdef CUDA_PATH
USE_GPU:=-gpu
endif

# ---------------------------------------------------------------------------------------
# SNIPPET pour identifier le nombre de processeur
NPROC?=$(shell nproc)

# ---------------------------------------------------------------------------------------
# SNIPPET pour pouvoir lancer un browser avec un fichier local
define BROWSER
	python -c '
	import os, sys, webbrowser
	from urllib.request import pathname2url

	webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])), autoraise=True)
	sys.exit(0)
	'
endef

# ---------------------------------------------------------------------------------------
# SNIPPET pour supprimer le parallelisme pour certaines cibles
# par exemple pour release
ifneq ($(filter configure release clean functional-test% upgrade-%,$(MAKECMDGOALS)),)
.NOTPARALLEL:
endif
#

# ---------------------------------------------------------------------------------------
# SNIPPET pour récupérer les séquences de caractères pour les couleurs
# A utiliser avec un
# echo -e "Use '$(cyan)make$(normal)' ..."
# Si vous n'utilisez pas ce snippet, les variables de couleurs non initialisés
# sont simplement ignorées.
ifneq ($(TERM),)
normal:=$(shell tput sgr0)
bold:=$(shell tput bold)
red:=$(shell tput setaf 1)
green:=$(shell tput setaf 2)
yellow:=$(shell tput setaf 3)
blue:=$(shell tput setaf 4)
purple:=$(shell tput setaf 5)
cyan:=$(shell tput setaf 6)
white:=$(shell tput setaf 7)
gray:=$(shell tput setaf 8)
endif

# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer le projet, le virtualenv conda.
# Par convention, les noms du projet, de l'environnement Conda
# correspondent au nom du répertoire du projet.
# Il est possible de modifier cela en valorisant les variables VENV, et/ou PRJ.
# avant le lancement du Makefile (`VENV=cntk_p36 make`)
PRJ:=$(shell basename $(shell pwd))
VENV ?= $(PRJ)

PRJ_PACKAGE:=$(PRJ)$(USE_GPU)
PYTHON_VERSION:=3.6
S3_BUCKET?=s3://$(subst _,-,$(PRJ))
PROFILE = default
DOCKER_REPOSITORY = $(USER)
# Data directory (can be in other place, in VM or Docker for example)
export DATA?=data

# Conda environment
CONDA_BASE:=$(shell conda info --base)
CONDA_PACKAGE:=$(CONDA_PREFIX)/lib/python$(PYTHON_VERSION)/site-packages
CONDA_PYTHON:=$(CONDA_PREFIX)/bin/python
CONDA_ARGS?=

PIP_PACKAGE:=$(CONDA_PACKAGE)/$(PRJ_PACKAGE).egg-link
PIP_ARGS?=


# ---------------------------------------------------------------------------------------
# SNIPPET pour ajouter des repositories complémentaires à PIP.
# A utiliser avec par exemple
# pip $(EXTRA_INDEX) install ...
EXTRA_INDEX:=--extra-index-url=https://pypi.anaconda.org/octo

# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer automatiquement l'aide du Makefile.
# Il faut utiliser des commentaires commençant par '##' précédant la ligne des recettes,
# pour une production automatique de l'aide.
.PHONY: help
.DEFAULT: help

## Print all majors target
help:
	@echo "$(bold)Available rules:$(normal)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=20 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')

	echo -e "Use '$(cyan)make -jn ...$(normal)' for Parallel run"
	echo -e "Use '$(cyan)make -B ...$(normal)' to force the target"
	echo -e "Use '$(cyan)make -n ...$(normal)' to simulate the build"

# ---------------------------------------------------------------------------------------
# SNIPPET pour affichier la valeur d'une variable d'environnement
# tel quelle est vue par le Makefile. Par exemple `make dump-CONDA_PACKAGE`
.PHONY: dump-*
dump-%:
	@if [ "${${*}}" = "" ]; then
		echo "Environment variable $* is not set";
		exit 1;
	else
		echo "$*=${${*}}";
	fi

# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer les Notebooks avec GIT.
# Les recettes suivantes s'assure que git est bien initialisé
# et ajoute des recettes pour les fichiers *.csv.
#
# Pour cela, un fichier .gitattribute est maintenu à jour.

# Les scripts pour les CSV utilisent le composant `daff` (pip install daff)
# pour comparer plus efficacement les évolutions des fichiers csv.
# Un `git diff toto.csv` est plus clair.

# S'assure de la présence de git (util en cas de synchronisation sur le cloud par exemple,
# après avoir exclus le répertoire .git (cf. ssh-ec2)
.git:
	@if [[ ! -d .git ]]; then
		@git init -q
		git commit --allow-empty -m "Create project $(PRJ)"
	fi



# Règle qui ajoute la validation du project avant un push sur la branche master.
# Elle ajoute un hook git pour invoquer `make validate` avant de pusher. En cas
# d'erreur, le push n'est pas possible.
# Pour forcer le push, malgres des erreurs lors de l'exécution de 'make validate'
# utilisez 'FORCE=y git push'.
# Pour supprimer ce comportement, il faut modifier le fichier .git/hooks/pre-push
# et supprimer la règle du Makefile, ou bien,
# utiliser un fichier vide 'echo ''> .git/hooks/pre-push'
.git/hooks/pre-push: | .git
	@# Add a hook to validate the project before a git push
	cat >>.git/hooks/pre-push <<PRE-PUSH
	#!/usr/bin/env sh
	# Validate the project before a push
	if test -t 1; then
		ncolors=$$(tput colors)
		if test -n "\$$ncolors" && test \$$ncolors -ge 8; then
			normal="\$$(tput sgr0)"
			red="\$$(tput setaf 1)"
	        green="\$$(tput setaf 2)"
			yellow="\$$(tput setaf 3)"
		fi
	fi
	branch="\$$(git branch | grep \* | cut -d ' ' -f2)"
	if [ "\$${branch}" = "master" ] && [ "\$${FORCE}" != y ] ; then
		printf "\$${green}Validate the project before push the commit... (\$${yellow}make validate\$${green})\$${normal}\n"
		make validate
		ERR=\$$?
		if [ \$${ERR} -ne 0 ] ; then
			printf "\$${red}'\$${yellow}make validate\$${red}' failed before git push.\$${normal}\n"
			printf "Use \$${yellow}FORCE=y git push\$${normal} to force.\n"
			exit \$${ERR}
		fi
	fi
	PRE-PUSH
	chmod +x .git/hooks/pre-push

# Init git configuration
.gitattributes: | .git .git/hooks/pre-push  # Configure git
	@git config --local core.autocrlf input
	# Set tabulation to 4 when use 'git diff'
	@git config --local core.page 'less -x4'


ifeq ($(shell which daff >/dev/null ; echo "$$?"),0)
	# Add rules to manage diff with daff for CSV file
	@git config --local diff.daff-csv.command "daff.py diff --git"
	@git config --local merge.daff-csv.name "daff.py tabular merge"
	@git config --local merge.daff-csv.driver "daff.py merge --output %A %O %A %B"
	@[ -e .gitattributes ] && grep -v daff-csv .gitattributes >.gitattributes.new 2>/dev/null
	@[ -e .gitattributes.new ] && mv .gitattributes.new .gitattributes
	@echo "*.[tc]sv diff=daff-csv merge=daff-csv -text" >>.gitattributes
endif


# ---------------------------------------------------------------------------------------
# SNIPPET pour vérifier la présence d'un environnement Conda conforme
# avant le lancement d'un traitement.
# Il faut ajouter $(VALIDATE_VENV) dans les recettes
# et choisir la version à appliquer.
# Soit :
# - CHECK_VENV pour vérifier l'activation d'un VENV avant de commencer
# - ACTIVATE_VENV pour activer le VENV avant le traitement
# Pour cela, sélectionnez la version de VALIDATE_VENV qui vous convient.
# Attention, toute les règles proposées ne sont pas compatible avec le mode ACTIVATE_VENV
CHECK_VENV=@if [[ "base" == "$(CONDA_DEFAULT_ENV)" ]] || [[ -z "$(CONDA_DEFAULT_ENV)" ]] ; \
  then ( echo -e "$(green)Use: $(cyan)conda activate $(VENV)$(green) before using 'make'$(normal)"; exit 1 ) ; fi

ACTIVATE_VENV=source $(CONDA_BASE)/etc/profile.d/conda.sh && conda activate $(VENV) $(CONDA_ARGS)
DEACTIVATE_VENV=source $(CONDA_BASE)/etc/profile.d/conda.sh && conda deactivate

VALIDATE_VENV=$(CHECK_VENV)
#VALIDATE_VENV=$(ACTIVATE_VENV)

# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer correctement toute les dépendences python du projet.
# La cible `requirements` se charge de gérer toutes les dépendences
# d'un projet Python. Dans le SNIPPET présenté, il y a de quoi gérer :
# - les dépendances PIP
#
# Il suffit, dans les autres de règles, d'ajouter la dépendances sur `$(REQUIREMENTS)`
# pour qu'un simple `make test` garantie la mise à jour de l'environnement avant
# le lancement des tests par exemple.
#
# Pour cela, il faut indiquer dans le fichier 'setup.py', toutes les dépendances
# de run et de test (voir le modèle de `setup.py` proposé)

# All dependencies of the project must be here
.PHONY: requirements dependencies
REQUIREMENTS=$(PIP_PACKAGE) \
	.gitattributes
requirements: $(REQUIREMENTS)
dependencies: requirements


# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer le mode offline.
# La cible `offline` permet de télécharger toutes les dépendences, pour pouvoir les utiliser
# ensuite sans connexion. Ensuite, il faut valoriser la variable d'environnement OFFLINE
# à True avant le lancement du make pour une utilisation sans réseau.
# `export OFFLINE=True
# make ...
# unset OFFLINE`

# TODO: faire une regle ~/.offline et un variable qui s'ajuste pour tirer la dépendances ?
# ou bien le faire à la main ?
# Download dependencies for offline usage
~/.mypypi: setup.py
	pip download '.[dev,test]' --dest ~/.mypypi
# Download modules and packages before going offline
offline: ~/.mypypi
ifeq ($(OFFLINE),True)
CONDA_ARGS+=--use-index-cache --use-local --offline
PIP_ARGS+=--no-index --find-links ~/.mypypi
endif

# Rule to check the good installation of python in Conda venv
$(CONDA_PYTHON):
	@$(VALIDATE_VENV)
	conda install -q "python=$(PYTHON_VERSION).*" -y $(CONDA_ARGS)

# Rule to update the current venv, with the dependencies describe in `setup.py`
$(PIP_PACKAGE): $(CONDA_PYTHON) setup.py | .git # Install pip dependencies
	@$(VALIDATE_VENV)
	echo -e "$(cyan)Install setup.py dependencies ... (may take minutes)$(normal)"
	pip install $(PIP_ARGS) $(EXTRA_INDEX) -e '.[dev,test]' | grep -v 'already satisfied' || true
	echo -e "$(cyan)setup.py dependencies updated$(normal)"
	@touch $(PIP_PACKAGE)





# ---------------------------------------------------------------------------------------
# SNIPPET pour préparer l'environnement d'un projet juste après un `git clone`
.PHONY: configure
## Prepare the work environment (conda venv, kernel, ...)
configure:
	@conda create --name "$(VENV)" python=$(PYTHON_VERSION) -y $(CONDA_ARGS)
	@if [[ "base" == "$(CONDA_DEFAULT_ENV)" ]] || [[ -z "$(CONDA_DEFAULT_ENV)" ]] ; \
	then echo -e "Use: $(cyan)conda activate $(VENV)$(normal) $(CONDA_ARGS)" ; fi

# ---------------------------------------------------------------------------------------
.PHONY: remove-venv
remove-$(VENV):
	@$(DEACTIVATE_VENV)
	conda env remove --name "$(VENV)" -y 2>/dev/null
	echo -e "Use: $(cyan)conda deactivate$(normal)"
# Remove virtual environement
remove-venv : remove-$(VENV)

# ---------------------------------------------------------------------------------------
# SNIPPET de mise à jour des dernières versions des composants.
# Après validation, il est nécessaire de modifier les versions dans le fichier `setup.py`
# pour tenir compte des mises à jours
.PHONY: upgrade-venv
upgrade-$(VENV):
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not upgrade virtual env in offline mode$(normal)"
else
	@$(VALIDATE_VENV)
	conda update --all $(CONDA_ARGS)
	pip list --format freeze --outdated | sed 's/(.*//g' | xargs -r -n1 pip install $(EXTRA_INDEX) -U
	@echo -e "$(cyan)After validation, upgrade the setup.py$(normal)"
endif
# Upgrade packages to last versions
upgrade-venv: upgrade-$(VENV)


# ---------------------------------------------------------------------------------------
# SNIPPET de validation des scripts en les ré-executant.
# Ces scripts peuvent être la traduction de Notebook Jupyter, via la règle `make nb-convert`.
# L'idée est d'avoir un sous répertoire par phase, dans le répertoire `scripts`.
# Ainsi, il suffit d'un `make run-phase1` pour valider tous les scripts du répertoire `scripts/phase1`.
# Pour valider toutes les phases : `make run-*`.
# L'ordre alphabétique est utilisé. Il est conseillé de préfixer chaque script d'un numéro.
.PHONY: run-*
scripts/.make-%: $(REQUIREMENTS)
	$(VALIDATE_VENV)
	time ls scripts/$*/*.py | grep -v __ | sed 's/\.py//g; s/\//\./g' | \
		xargs -L 1 -t python -O -m
	@date >scripts/.make-$*

# All phases
scripts/phases: $(sort $(subst scripts/,scripts/.make-,$(wildcard scripts/*)))

## Invoke all script in lexical order from scripts/<% dir>
run-%:
	$(MAKE) scripts/.make-$*

# ---------------------------------------------------------------------------------------
# SNIPPET pour valider le code avec flake8 et pylint
.PHONY: lint
.pylintrc:
	pylint --generate-rcfile > .pylintrc

.make-lint: $(REQUIREMENTS) $(PYTHON_SRC) | .pylintrc
	$(VALIDATE_VENV)
	@echo -e "$(cyan)Check lint...$(normal)"
	@echo "---------------------- FLAKE"
	@flake8 $(PRJ_PACKAGE)
	@echo "---------------------- PYLINT"
	@pylint $(PRJ_PACKAGE)
	touch .make-lint

## Lint the code
lint: .make-lint


# ---------------------------------------------------------------------------------------
# SNIPPET pour valider le typage avec pytype
$(CONDA_PREFIX)/bin/pytype:
	@pip install $(PIP_ARGS) -q pytype

pytype.cfg: $(CONDA_PREFIX)/bin/pytype
	@[[ ! -f pytype.cfg ]] && pytype --generate-config pytype.cfg || true
	touch pytype.cfg

.PHONY: typing
.make-typing: $(REQUIREMENTS) $(CONDA_PREFIX)/bin/pytype pytype.cfg $(PYTHON_SRC)
	$(VALIDATE_VENV)
	@echo -e "$(cyan)Check typing...$(normal)"
	# pytype
	pytype "$(PRJ)"
	for phase in scripts/*
	do
	  ( cd $$phase ; find -L . -type f -name '*.py' -exec pytype {} \; )
	done
	touch ".pytype/pyi/$(PRJ)"
	touch .make-typing

	# mypy
	# TODO: find Pandas stub
	# MYPYPATH=./stubs/ mypy "$(PRJ)"
	# touch .make-mypy

## Check python typing
typing: .make-typing

## Add infered typing in module
add-typing: typing
	@find -L "$(PRJ)" -type f -name '*.py' -exec merge-pyi -i {} .pytype/pyi/{}i \;
	for phase in scripts/*
	do
	  ( cd $$phase ; find -L . -type f -name '*.py' -exec merge-pyi -i {} .pytype/pyi/{}i \; )
	done





# ---------------------------------------------------------------------------------------
# SNIPPET pour créer la documentation html et pdf du projet.
# Il est possible d'indiquer build/XXX, ou XXX correspond au type de format
# à produire. Par exemple: html, singlehtml, latexpdf, ...
# Voir https://www.sphinx-doc.org/en/master/usage/builders/index.html
.PHONY: docs
# Use all processors
#PPR SPHINX_FLAGS=-j$(NPROC)
SPHINX_FLAGS=
# Generate API docs
docs/source: $(REQUIREMENTS) $(PYTHON_SRC)
	$(VALIDATE_VENV)
	sphinx-apidoc -f -o docs/source $(PRJ)/
	touch docs/source

# Build the documentation in specificed format (build/html, build/latexpdf, ...)
build/%: $(REQUIREMENTS) docs/source docs/* *.md | .git
	@$(VALIDATE_VENV)
	@TARGET=$(*:build/%=%)
ifeq ($(OFFLINE),True)
	if [ "$$TARGET" != "linkcheck" ] ; then
endif
	@echo "Build $$TARGET..."
	@LATEXMKOPTS=-silent sphinx-build -M $$TARGET docs build $(SPHINX_FLAGS)
	touch build/$$TARGET
ifeq ($(OFFLINE),True)
	else
		@echo -e "$(red)Can not to build '$$TARGET' in offline mode$(normal)"
	fi
endif
# Build all format of documentations
## Generate and show the HTML documentation
docs: build/html
	@$(BROWSER) build/html/index.html


# ---------------------------------------------------------------------------------------
# SNIPPET pour créer une distribution des sources
.PHONY: sdist
dist/$(PRJ_PACKAGE)-*.tar.gz: $(REQUIREMENTS)
	@$(VALIDATE_VENV)
	python setup.py sdist

# Create a source distribution
sdist: dist/$(PRJ_PACKAGE)-*.tar.gz

# ---------------------------------------------------------------------------------------
# SNIPPET pour créer une distribution des binaires au format egg.
# Pour vérifier la version produite :
# python setup.py --version
# Cela correspond au dernier tag d'un format 'version'
.PHONY: bdist
dist/$(subst -,_,$(PRJ_PACKAGE))-*.whl: $(REQUIREMENTS)
	@$(VALIDATE_VENV)
	python setup.py bdist_wheel

# Create a binary wheel distribution
bdist: dist/$(subst -,_,$(PRJ_PACKAGE))-*.whl


# ---------------------------------------------------------------------------------------
# SNIPPET pour créer une distribution des binaires au format egg.
# Pour vérifier la version produite :
# python setup.py --version
# Cela correspond au dernier tag d'un format 'version'
.PHONY: dist

## Create a full distribution
dist: bdist sdist

# ---------------------------------------------------------------------------------------
# SNIPPET pour tester la publication d'une distribution avant sa publication.
.PHONY: check-twine
## Check the distribution before publication
check-twine: bdist
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not check-twine in offline mode$(normal)"
else
	$(VALIDATE_VENV)
	twine check dist/*
endif

# ---------------------------------------------------------------------------------------
# SNIPPET pour tester la publication d'une distribution
# sur test.pypi.org.
.PHONY: test-twine
## Publish distribution on test.pypi.org
test-twine: bdist
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not test-twine in offline mode$(normal)"
else
	$(VALIDATE_VENV)
	twine upload --sign --repository-url https://test.pypi.org/legacy/ dist/*
	# PPR ls . --hide "*.dev*" | xargs twine upload --sign --repository-url https://test.pypi.org/legacy/
endif

# ---------------------------------------------------------------------------------------
# SNIPPET pour publier la version sur pypi.org.
.PHONY: release
## Publish distribution on pypi.org
release: dist
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not release in offline mode$(normal)"
else
	@$(VALIDATE_VENV)
	[[ $$(ls -1 dist --hide "*.dev*" | wc -l) -ne 0 ]] || echo -e "$(red)Add a tag version in GIT to release$(normal)"
	echo "Enter Pypi password"
	ls $(PWD)/dist/* --hide "*.dev*" | xargs twine upload
endif



# ---------------------------------------------------------------------------------------
# SNIPPET pour installer aws cli.
$(CONDA_PREFIX)/bin/aws:
	@pip install $(PIP_ARGS) -q awscli



# Download raw data if necessary
$(DATA)/raw:




# ---------------------------------------------------------------------------------------
# SNIPPET pour nettoyer tous les fichiers générés par le compilateur Python.
.PHONY: clean-pyc
# Clean pre-compiled files
clean-pyc:
	@/usr/bin/find -L . -type f -name "*.py[co]" -delete
	@/usr/bin/find -L . -type d -name "__pycache__" -delete

# ---------------------------------------------------------------------------------------
# SNIPPET pour nettoyer les fichiers de builds (package et docs).
.PHONY: clean-build
# Remove build artifacts and docs
clean-build:
	@/usr/bin/find -L . -type f -name ".make-*" -delete
	@rm -fr build/
	@rm -fr dist/*
	@rm -fr *.egg-info
	@echo -e "$(cyan)Build cleaned$(normal)"


# ---------------------------------------------------------------------------------------
.PHONY: clean-pip
# Remove all the pip package
clean-pip:
	@$(VALIDATE_VENV)
	pip freeze | grep -v "^-e" | xargs pip uninstall -y
	@echo -e "$(cyan)Virtual env cleaned$(normal)"

# ---------------------------------------------------------------------------------------
# SNIPPET pour nettoyer complètement l'environnement Conda
.PHONY: clean-venv clean-$(VENV)
clean-$(VENV): remove-venv
	@conda create -y -q -n $(VENV) $(CONDA_ARGS)
	@touch setup.py
	@echo -e "$(yellow)Warning: Conda virtualenv $(VENV) is empty.$(normal)"
# Set the current VENV empty
clean-venv : clean-$(VENV)

# ---------------------------------------------------------------------------------------
# SNIPPET pour faire le ménage du projet (hors environnement)
.PHONY: clean
## Clean current environment
clean: clean-pyc clean-build

# ---------------------------------------------------------------------------------------
# SNIPPET pour faire le ménage du projet
.PHONY: clean-all
# Clean all environments
clean-all: clean remove-venv

# ---------------------------------------------------------------------------------------
# SNIPPET pour executer les tests unitaires et les tests fonctionnels.
# Utilisez 'NPROC=1 make unit-test' pour ne pas paralléliser les tests
# Voir https://setuptools.readthedocs.io/en/latest/setuptools.html#test-build-package-and-run-a-unittest-suite
ifeq ($(shell test $(NPROC) -gt 1; echo $$?),0)
PYTEST_ARGS ?=-n $(NPROC)
else
PYTEST_ARGS ?=
endif
.PHONY: test unittest functionaltest
.make-unit-test: $(REQUIREMENTS) $(PYTHON_TST) $(PYTHON_SRC)
	@$(VALIDATE_VENV)
	@echo -e "$(cyan)Run unit tests...$(normal)"
	python -m pytest  -s tests $(PYTEST_ARGS) -m "not functional"
	@date >.make-unit-test
# Run only unit tests
unit-test: .make-unit-test

.make-functional-test: $(REQUIREMENTS) $(PYTHON_TST) $(PYTHON_SRC)
	@$(VALIDATE_VENV)
	@echo -e "$(cyan)Run functional tests...$(normal)"
	python -m pytest  -s tests $(PYTEST_ARGS) -m "functional"
	@date >.make-functional-test
# Run only functional tests
functional-test: .make-functional-test

.make-test: $(REQUIREMENTS) $(PYTHON_TST) $(PYTHON_SRC)
	@echo -e "$(cyan)Run all tests...$(normal)"
	python -m pytest $(PYTEST_ARGS) -s tests
	#python setup.py test
	@date >.make-test
	@date >.make-unit-test
	@date >.make-functional-test
## Run all tests (unit and functional)
test: .make-test


# SNIPPET pour vérifier les TU et le recalcul de tout les notebooks et scripts.
# Cette règle est invoqué avant un commit sur la branche master de git.
.PHONY: validate
.make-validate: .make-test typing $(DATA)/raw scripts/* build/html build/linkcheck
	@date >.make-validate
## Validate the version before release
validate: .make-validate

# ---------------------------------------------------------------------------------------
# SNIPPET pour ajouter la capacité d'exécuter des recettes sur une instance éphémère EC2.
# Voir https://gitlab.octo.com/pprados/ssh-ec2
# L'utilisation de `$(REQUIREMENTS)` dans chaque règle, permet de s'assurer de la bonne
# mise en place de l'environnement nécessaire à l'exécution de la recette,
# même lorsqu'elle est exécuté sur EC2.
# Par exemple :
# - `make on-ec2-test` execute les TU sur EC2 (Invoque `make test`)
# - `make detach-train` détache le l'apprentissage (Invoque `make train`)

# Conda virtual env to use in EC2
VENV_AWS=tensorflow_p36

# Initialize EC2 instance
# The two first lines add a log of the script in /tmp/user-data.log
# for debug
export AWS_USER_DATA
define AWS_USER_DATA
#!/bin/bash -x
exec > /tmp/user-data.log 2>&1
sudo su - ec2-user -c "conda install -n $(VENV_AWS) make>=4 -y $(CONDA_ARGS)"
endef

# What is the life cycle of EC2 instance  via ssh-ec2 ?
#--leave --stop or --terminate
EC2_LIFE_CYCLE?=--terminate

# Recette permettant un `make ec2-test`
.PHONY: ec2-* ec2-tmux-* ec2-detach-* ec2-notebook ec2-ssh
## Call 'make %' recipe on EC2 (`make ec2-train`)
ec2-%: $(CONDA_PREFIX)/bin/aws clean-pyc
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not use ssh-ec2 in offline mode$(normal)"
else
	set -x
	ssh-ec2 $(EC2_LIFE_CYCLE) "source activate $(VENV_AWS) ; LC_ALL="en_US.UTF-8" VENV=$(VENV_AWS) make $(*:ec2-%=%)"
endif

# Recette permettant d'exécuter une recette avec un tmux activé.
# Par exemple `make ec2-tmux-train`
## Call 'make %' recipe on EC2 with a tmux session (`make ec2-tmux-train`)
ec2-tmux-%: $(CONDA_PREFIX)/bin/aws clean-pyc
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not use ssh-ec2 in offline mode$(normal)"
else
	@$(VALIDATE_VENV)
	set -x
	NO_RSYNC_END=n ssh-ec2 --multi tmux --leave "source activate $(VENV_AWS) ; LC_ALL="en_US.UTF-8" VENV=$(VENV_AWS) make $(*:ec2-tmux-%=%)"
endif

# Recette permettant un `make ec2-detach-test`
# Il faut faire un ssh-ec2 --finish pour rapatrier les résultats à la fin
## Call 'make %' recipe on EC2 and detach immediatly (`make ec2-detach-train`)
ec2-detach-%: $(CONDA_PREFIX)/bin/aws clean-pyc
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not use ssh-ec2 in offline mode$(normal)"
else
	@$(VALIDATE_VENV)
	set -x
	ssh-ec2 --detach $(EC2_LIFE_CYCLE) "source activate $(VENV_AWS) ; LC_ALL="en_US.UTF-8" VENV=$(VENV_AWS) make $(*:ec2-detach-%=%)"
endif

# Recette permettant un `make ec2-attach`
# Il faut faire un ssh-ec2 --finish pour rapatrier les résultats à la fin
## Call 'make %' recipe on EC2 and detach immediatly (`make ec2-detach-train`)
ec2-attach: $(CONDA_PREFIX)/bin/aws
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not use ssh-ec2 in offline mode$(normal)"
else
	@$(VALIDATE_VENV)
	set -x
	ssh-ec2 --attach
endif

# Recette permettant un `make ec2-terminate`
## Call 'make %' recipe on EC2 and detach immediatly (`make ec2-detach-train`)
ec2-terminate: $(CONDA_PREFIX)/bin/aws
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not use ssh-ec2 in offline mode$(normal)"
else
	@$(VALIDATE_VENV)
	set -x
	ssh-ec2 --finish
endif

## Start jupyter notebook on EC2
ec2-notebook: $(CONDA_PREFIX)/bin/aws
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not use ssh-ec2 in offline$(normal)"
else
	set -x
	ssh-ec2 --stop -L 8888:localhost:8888 "jupyter notebook --NotebookApp.open_browser=False"
endif


## Install the tools in conda env
install: $(CONDA_PREFIX)/bin/$(PRJ)

## Install the tools in conda env with 'develop' link
develop:
	python setup.py develop

## Install the tools in conda env
uninstall: $(CONDA_PREFIX)/bin/$(PRJ)
	rm $(CONDA_PREFIX)/bin/$(PRJ)


# Recette permettant un `make installer` pour générer un programme autonome comprennant le code et
# un interpreteur Python. Ainsi, il suffit de le copier et de l'exécuter sans pré-requis
dist/$(PRJ)$(EXE): .make-validate
	# FIXME: faire un installer pour Alpine ?
	@PYTHONOPTIMIZE=2 && pyinstaller --onefile $(PRJ)/$(PRJ).py
	echo -e "$(cyan)Executable is here 'dist/$(PRJ)$(EXE)'$(normal)"
## Build standalone executable for this OS
installer: dist/$(PRJ)$(EXE)




#################################################################################
# PROJECT RULES                                                                 #
#################################################################################
#
# ┌─────────┐ ┌──────────┐ ┌───────┐ ┌──────────┐ ┌───────────┐
# │ prepare ├─┤ features ├─┤ train ├─┤ evaluate ├─┤ visualize │
# └─────────┘ └──────────┘ └───────┘ └──────────┘ └───────────┘
#

.PHONY: prepare features train evaluate visualize
# Meta parameters
# TODO: Ajustez les meta-paramètres
ifdef DEBUG
EPOCHS :=--epochs 1
BATCH_SIZE :=--batch-size 1
else
EPOCHS :=--epochs 10
BATCH_SIZE :=--batch-size 16
endif
SEED :=--seed 12345

# Rule to declare an implicite dependencies from sub module for all root project files
TOOLS:=$(shell find sd2c/ -mindepth 2 -type f -name '*.py')
sd2c/*.py : $(TOOLS)
	@touch $@



