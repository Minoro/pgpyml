from sklearn.tree import DecisionTreeClassifier
from sklearn import datasets
from joblib import dump, load

iris = datasets.load_iris()
X = iris.data
y = iris.target

model = DecisionTreeClassifier()

model.fit(X, y)

print('Saving model...')
dump(model, './iris_decision_tree.joblib')
    
print('Model saved!')
print('Done!')