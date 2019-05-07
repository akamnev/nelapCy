"""Отображение из точной части речи в универсальную"""
TAG_MAP = {
    '"': 'PUNCT',
    '$': 'SYM',
    '(': 'PUNCT',
    ')': 'PUNCT',
    ',': 'PUNCT',
    '.': 'PUNCT',
    ':': 'PUNCT',
    'ABB': 'X',
    'CC': 'CCONJ',
    'CD': 'NUM',
    'CT': 'X',
    'HT': 'X',
    'DT': 'DET',
    'EMJ': 'X',
    'Ex': 'ADV',
    'FW': 'X',
    'IN': 'ADP',
    'JJ': 'ADJ',
    'JJR': 'ADJ',
    'JJS': 'ADJ',
    'MD': 'VERB',
    'NN': 'NOUN',
    'NNP': 'PROPN',
    'NNPS': 'PROPN',
    'NNS': 'NOUN',
    'PDT': 'ADJ',
    'POS': 'PART',
    'PRP': 'PRON',
    'PRP$': 'ADJ',
    'RB': 'ADV',
    'RBR': 'ADV',
    'RBS': 'ADV',
    'RP': 'PART',
    'SYM': 'SYM',
    'TO': 'PART',
    'UH': 'INTJ',
    'URL': 'X',
    'USR': 'X',
    'VB': 'VERB',
    'VBD': 'VERB',
    'VBG': 'VERB',
    'VBN': 'VERB',
    'VBP': 'VERB',
    'VBZ': 'VERB',
    'WDT': 'ADJ',
    'WP': 'NOUN',
    'WP$': 'ADJ',
    'WRB': 'ADV,',
}
