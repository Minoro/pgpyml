# PGPYML

Pgpyml is an extension that allows you to use your models written in Python inside PostgreSQL. You can make prediction directly on the data being entered at your base, you can also create triggers to avoid insertions based on the predictions.

Python is a popular language to develop machine learning solutions. You may use this language to do some exploratory data analysis and write a model to do predictions over new data to your users. When you are satisfied with the results produced by your model you will deploy it, but this task can be time-consuming. With `pgpyml` you can easly use your model as an in-database solution and take the [advantages of this approach](https://blogs.oracle.com/bigdata/post/why-you-should-use-your-database-for-machine-learning).


This extension is under development, designed to be compatible with `sklearn` and is not ready to be used in the production environment.

# Instalation

This section will instruct you how to install the `pgpyml` extension. You must follow the [Prerequisites](#rerequisites) section and chose the [git installation instructions](#install-with-git) or the [pgxnclient instructions](#install-with-pgnxclient). Once you the installation is done you can [create the extension]() on you database.

## Prerequisites

First of all, you will need to install the python libraries that are used to write and run your machine learning models:
```
pip3 install numpy scikit-learn pandas
```

This command you install the `numpy`, `sklearn` and `pandas` libraries. The `pgpyml` extension expects that you use `sklearn` to build your models.

You will need to install the python extension to PostgreSQL. You can do this with the command:
```
# Replace the <version> with your postgres version
apt -y install postgresql-plpython3-<version>
```

Replace the `<version>` in the command with the Postgres version that you are using, for example, if you want to install the python extension to Postgres 13 use:
```
apt -y install postgresql-plpython3-13
```

## Install with Git

You can install the `pgpyml` with git, cloning the repository and running the instalation script. To do this, first clone the extension's repository:

```
git clone -b v0.1.0 https://github.com/Minoro/pgpyml.git
```

Change the `v0.1.0` to the [desired version](https://github.com/Minoro/pgpyml/tags). And inside the downloaded folder run the make file:
```
make install
make clean
```

This should install the extension and make it available to be used in the Postgres.

## Install with PGNXClient

Alternatively you can install the extension using the `pgnxclient`, you will need to install it if you don't already have it:

```
apt install pgxnclient
```

And then you can install the `pgpyml` extension with:
```
pgxn install pgpyml
```

## Creating the Extension

After you have installed the extension you can create it on your database. To do this, you need to connect to the desired database and create the python extension and the `pgpyml`:

```sql
-- Python Language extension
CREATE EXTENSION plpython3u;

-- The pgpyml extension
CREATE EXTENSION pgpyml;
```

Now you are ready to use your machine learning model inside your database.


