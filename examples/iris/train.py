# Script: train.py
from sklearn.tree import DecisionTreeClassifier
from sklearn import datasets
from joblib import dump, load

iris = datasets.load_iris()
X = iris.data  # we only take the first two features.
y = iris.target

model = DecisionTreeClassifier()

model.fit(X, y)
dump(model, './iris_decision_tree.joblib')