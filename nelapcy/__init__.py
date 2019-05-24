# TODO: не плохо было бы сделать какую-то логику загрузки модлей и данных как в spaCy
# Но что конкретно делать не понятно
import os
import pickle
DIR = os.path.abspath(os.path.dirname(__file__))


def load(name):
    """Загрузка только словаря векторов"""
    file = os.path.join(DIR, 'data', name, 'vectors.pkl')
    with open(file, 'rb') as fp:
        vectors = pickle.load(fp)
    return vectors
