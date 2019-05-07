# coding: utf8
URL0 = (
    r"(?=[\w])"
    # protocol identifier
    r"(?:(?:https?|ftp|mailto)://)?"  # specific 
    # user:pass authentication
    r"(?:\S+(?::\S*)?@)?"   # specific
    # IP address exclusion
    # private & local networks
    r"(?!(?:10|127)(?:\.\d{1,3}){3})"
    r"(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})"
    r"(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})"
    # IP address dotted notation octets
    # excludes loopback network 0.0.0.0
    # excludes reserved space >= 224.0.0.0
    # excludes network & broadcast addresses
    # (first & last IP address of each class)
    # MH: Do we really need this? Seems excessive, and seems to have caused
    # Issue #957
    r"(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])"
    r"(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}"
    r"(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))"
    # port number
    r"(?::\d{2,5})?"
    # resource path
    r"(?:/\S*)?"
    # query parameters
    r"\??(:?\S*)?"
    r"(?<=[\w/])"
    # no punctuation
).strip()

URL1 = (
    # in order to support the prefix tokenization (see prefix test cases in test_urls).
    r"(?=[\w])"
    r"(?:"
    # protocol identifier
    r"(?:(?:https?|ftp|mailto)://)"
    r"|"
    # user:pass authentication
    r"(?:\S+(?::\S*)?@)"
    r")"
    # host name
    r"(?:(?:[a-zA-Z0-9]*)?[a-zA-Z0-9]+)"
    # domain name
    r"(?:\.(?:[a-zA-Z0-9])*[a-zA-Z0-9]+)*"
    # TLD identifier
    r"(?:\.(?:[a-zA-Z]{2,}))"
    # port number
    r"(?::\d{2,5})?"
    # resource path
    r"(?:/\S*)?"
    # query parameters
    r"(:?\?\S*)?"
    r"(?<=[\w/])"
).strip()


URL2 = (
    r"(?=[\w])"
    # host name
    r"(?:(?:[a-zA-Z0-9\-]*)?[a-zA-Z0-9]+)"
    # domain name
    r"(?:\.(?:[a-zA-Z0-9])*[a-zA-Z0-9]+)*"
    # TLD identifier
    r"(?:\.(?:com|edu|gov|int|mil|net|org|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bl|bm|bn|bo|bq|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mf|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw))"
    # in order to support the suffix tokenization (see suffix test cases in test_urls),
    r"(?<=[\w/])"
    # no punctuation
).strip()

# URL_PATTERN = _url = r"(?:www\.|http://|https://)(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+"

HASHTAG = r'(?<!\w)#(\w+|\w+\.\w+)(?!\w)'
CASHTAG = r"(?:(?<=^)|(?<=\s))\$[a-zA-Z][a-zA-Z0-9]*([\._][a-zA-Z0-9]+)?"
MENTION = r'@\w+(?!\w)'
EMAIL = r"\b[[:alnum:].%+-]+(?:@| \[at\] )[[:alnum:].-]+(?:\.| \[?dot\]? )[[:alpha:]]{2,}\b"
MONEY = r"\d+[kKmM]"
# \$£€¥฿₽
NUMBERS = r"(?:(?<=\s)|(?<=^)|(?<!\w))[\d]+([\d\,\.':]+[\d]+)?"
NUMBERS_SIGN = r"(?:(?<=\s)|(?<=^)|(?<=\w)|(?<=\())[\+\-]+[\d]+([\d\,\.':]+[\d]+)?"
NUM_TH = r"(?:(?<=\s)|(?<=\$))[\d]+(th|TH|s|G|g|B|b|PM|h)"  # 8th, 25th 1980s 4G 10B 24h
POS = r"(?<=\w)['’](s|m|re|d|ve|ll|t)(?=\s)"  # притяжательная форма
# WORD_WITH_NUMBER = r"(\w+\-\d+|\d+\-+\w+)"
WORD_WITH_NUMBER = r"(?:\d+\-+\w+)"

ABB = r"(?:\w\.){2,}"
AGE = r"\d+\-year(?:s)?\-old"
NEO = r"[nN]eo\-+\w+"
CO = r"(CO|Co|co)\-+\w+"  # co-conspirator
RB = r"(?<=\w)n['’]t(?=\s)"
# TODO cant ????
RBL = r"(?<![a-zA-Z])(ca|can|Can|do|did|does)(?=(not|n['’]t|nt))"
RBR = r"(?:(?<=can)|(?<=Can)|(?<=do)|(?<=did)|(?<=does)|(?<=ca))(not|n['’]t|nt)(?![a-zA-Z])"

QL = r"\"(?=\w)"  # aaa "Bert
QR = r"(?<=\w)\""  # aaa "Bert
BR = r"\((?=\w)"  # (AAA
BL = r"(?<=\w)\)"  # AAA)

WALLET = r"0x[0-9a-fA-F]+"
ETC_DOTS = r'(?<=etc)\.+'

# TODO: IGNORE CASE????

TOKEN_MATCH = (
    '|'.join(
        [
            URL0,
            URL1,
            URL2,
            HASHTAG,
            CASHTAG,
            MENTION,
            EMAIL,
            WALLET,
            MONEY,
            AGE,
            WORD_WITH_NUMBER,
            NUM_TH,  # важно располождение до NUMBERS
            NUMBERS,
            NUMBERS_SIGN,
            POS,
            ABB,
            NEO,
            RB, RBL, RBR,
            BR, BL,
            CO,
            QL, QR,
            ETC_DOTS,
        ])
)


PUNC = r"([\.,\-\!\?\:…]+)"
SYM = r"(\-+\>+|<->)"

PUNC_MATCH = (
    '|'.join(
        [
            SYM,
            PUNC,
        ])
)

__all__ = ['TOKEN_MATCH', 'PUNC_MATCH']