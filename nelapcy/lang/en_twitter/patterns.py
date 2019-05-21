# coding: utf8
from ..char_classes import CONCAT_BRACKET, CONCAT_CURRENCY, CONCAT_HYPHENS, CONCAT_SYMBOL, CONCAT_PUNCT, CONCAT_QUOTES

IP = (
    r"((?<=\s)|(?<=^))"
    # protocol identifier
    r"((https?|h..ps?|ftp|rmp|rtsp|file|data|tel|xmpp|wais|telnet|prospero|smb|irc|nntp|news|gopher|mailto)://)?"
    # ip
    r"(?<![\d\.])((2[0-5]{2}|1\d{2}|[1-9]\d|\d)[%s]?\.[%s]?){3}(2[0-5]{2}|1\d{2}|[1-9]\d|\d)"
    # port number
    r"(\:\d{2,5})?"
    # resource path
    r"(/[^\s%s]*)?"
    r"((?=[…,;¿¡\*。，、；·।،\.])|(?=$)|(?=\s)|(?=\D))"
    ) % (CONCAT_BRACKET, CONCAT_BRACKET, CONCAT_QUOTES)
URL1 = (
    # protocol identifier
    r"(https?|ftp|rmp|rtsp|file|data|tel|xmpp|wais|telnet|prospero|smb|irc|nntp|news|gopher|mailto)://"
    # host name
    r"(?:[a-zA-Z0-9][a-zA-Z0-9\-]*)"
    # domain name
    r"(?:\.[a-zA-Z0-9][a-zA-Z0-9\-]*)*"
    # TLD identifier
    r"(?:\.(?:[a-zA-Z]{2,}))"
    # port number
    r"(\:\d{2,5})?"
    # resource path
    r"(/\w*)?"
)

URL2 = (
    r"((?<=\s)|(?<=^))"
    # host name
    r"[a-zA-Z0-9][a-zA-Z0-9\-]*"
    # domain name
    r"(\.[a-zA-Z0-9]*[a-zA-Z0-9]+)*"
    # TLD identifier
    r"(\.(com|edu|gov|int|mil|net|org|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bl|bm|bn|bo|bq|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mf|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw))"
    # r"(\.|\/[a-zA-Z0-9]*[a-zA-Z0-9]+)*"
    r"((?=[%s])|(?=$)|(?=\s))"
) % (CONCAT_PUNCT, )
HASHTAG = r'(?<!\w)#(\w+\.?\w+)(?!\w)'
CASHTAG = r"(?:(?<=^)|(?<=\s))\$[a-zA-Z]\w*([\._]\w+)?"
MENTION = r'(?:(?<=^)|(?<=\s)|(?<!\w))@\w+'
EMAIL = r"(?:(?<=^)|(?<=\s)|(?<!\w))[\w\-\.]+@[\w\-]+(\.\w+)+"
NUMBERS = (
    r"((?<=^)|(?<=[\s%s%s%s%s])|(?<=\d[%s]))[\+%s]*\d+([\,\-\.\/:']\d+)*"
    r"((million|st|rd|nd|th|gb|s|t|g|b|h|k|m)(?!\w))?"
    % (CONCAT_PUNCT, CONCAT_BRACKET, CONCAT_QUOTES, CONCAT_CURRENCY, CONCAT_HYPHENS, CONCAT_HYPHENS)
)
POS = r"(?<=\w)[\'`‘´’](s|m|re|d|ve|ll)(?=\s)" # притяжательная форма
WORD_WITH_NUMBER = (
    r"((?<=^)|(?<=[\\\/\s%s%s%s]))"
    r"(\d+[\,'\.]?)+\d+"
    r"("
    r"[%s]+"
    r"[a-zA-Z]+"
    r")+"
    r"((?=$)|(?=[\\\/\s%s%s%s]))"
    % (CONCAT_BRACKET, CONCAT_QUOTES, CONCAT_PUNCT, CONCAT_HYPHENS, CONCAT_BRACKET, CONCAT_QUOTES, CONCAT_PUNCT, )
)
WORD_NUMBER = (
    r"((?<=^)|(?<=[\\\/\s%s%s%s]))[a-z]+[%s]+\d+((?=$)|(?=[\\\/\s%s%s%s]))" %
    (CONCAT_BRACKET, CONCAT_QUOTES, CONCAT_PUNCT, CONCAT_HYPHENS, CONCAT_BRACKET, CONCAT_QUOTES, CONCAT_PUNCT)
)

ABB = (
        r"((?<=^)|(?<=[\\\/\s%s%s%s]))([a-zA-Z]{1,2}\.){2,}[a-zA-Z]?((?=$)|(?=[\\\/\s%s%s%s]))" %
        (CONCAT_BRACKET, CONCAT_QUOTES, CONCAT_PUNCT, CONCAT_BRACKET, CONCAT_QUOTES, CONCAT_PUNCT)
)
PREFIX_WORD = (
    r"((?<=^)|(?<=[\\\/\s%s%s%s]))(?i:(anti|self|neo|al|co|ex|pre|re|sub|in|non))[%s]+[a-zA-Z]+" %
    (CONCAT_BRACKET, CONCAT_QUOTES, CONCAT_PUNCT, CONCAT_HYPHENS, )
)

RB = r"(?<=\w)n[\'`‘´’]t\w*"
RBL = (
    r"(?<![a-z])(would|should|might|need|must|have|shall|could|dose|will|does|were|been|has|had|may|can|did|was|are|ca|am|is|do|wo|ai)"
    r"(?=(not|n[\'`‘´’]t|nt))"
)
RBR = (
    r"(?:(?<=would)|(?<=should)|(?<=shoud)|(?<=might)|(?<=need)|(?<=must)|(?<=have)|(?<=shall)|(?<=could)|(?<=dose)|"
    r"(?<=will)|(?<=does)|(?<=were)|(?<=been)|(?<=has)|(?<=had)|(?<=may)|(?<=can)|(?<=did)|(?<=was)"
    r"|(?<=are)|(?<=ca)|(?<=am)|(?<=is)|(?<=do)|(?<=wo)|(?<=ai))"
    r"(not|n[\'`‘´’]t|nt)"
    r"(?![a-z])"
)

PVR = (
    r"("
    r"(?<=[\s{p}]they)(re|ll|d)(?![a-z])"
    r"|"
    r"(?<=[\s{p}]she)(s)(?![a-z])"
    r"|"
    r"(?<=[\s{p}]you)(re|ll|d)(?![a-z])"
    r"|"
    r"(?<=[\s{p}]it)(ll|d)(?![a-z])"
    r"|"
    r"(?<=[\s{p}]he)(s)(?![a-z])"
    # r"|"
    # r"((?<=[\s{p}]we)|(?<=[\s]i))"  # nothing
    r"|"
    r"(?<=[\s{p}]i)(m)(?![a-z])"
    r")".format(p=CONCAT_PUNCT+CONCAT_HYPHENS+CONCAT_BRACKET+CONCAT_QUOTES)
)

PVL = (
    r"("
    r"(?<=[\s{p}])they(?=((re|ll|d)(?![a-z])))"
    r"|"
    r"(?<=[\s{p}])she(?=(s(?![a-z])))"
    r"|"
    r"(?<=[\s{p}])you(?=(re|ll|d)(?![a-z]))"
    r"|"
    r"(?<=[\s{p}])it(?=(ll|d)(?![a-z]))"
    r"|"
    r"(?<=[\s{p}])he(?=s(?![a-z]))"
    # r"|"
    # r"((?<=[\s{p}]we)|(?<=[\s]i))"  # nothing
    r"|"
    r"(?<=[\s{p}])i(?=m(?![a-z]))"
    r")".format(p=CONCAT_PUNCT+CONCAT_HYPHENS+CONCAT_BRACKET+CONCAT_QUOTES)
)

QL = r"(?<!\w)[\"“«「『']+(?=\w)"  # aaa "Bert
QR = r"(?<=\w)[\"”»」』]+(?!\w)"  # aaa "Bert
BR = r"(?<=[\w%s])[\)\]\}>）〕】》〉]" % (CONCAT_SYMBOL, )  # AAA)
BL = r"[\(\[\{<（〔【《〈](?=[\w%s])" % (CONCAT_SYMBOL + CONCAT_CURRENCY, )  # (AAA


EMOJI = (
    r"("
    r"[:;；：]( )?[\-–—]?( )?[\)\]\}>）〕】》〉]+"
    r"|"
    r"[>]*[:;；：][\'´’]?[\-–—]?[\(\[\{<（〔【《〈]+"
    r"|"
    r"(<3)"
    r")"
)
WALLET = r"0x[0-9a-fA-F]+"
ETC_DOTS = r'(?<=etc)\.+'
VERSION_ = r"(\w+[%s]+)+v(\d+\.)*\d+" % (CONCAT_HYPHENS, )

TOKEN_MATCH = (
    '|'.join(
        [
            IP,
            URL1,
            URL2,
            HASHTAG,
            CASHTAG,
            MENTION,
            EMAIL,
            WALLET,
            PREFIX_WORD,
            WORD_NUMBER,
            WORD_WITH_NUMBER,
            NUMBERS,
            POS,
            ABB,
            EMOJI,
            RB, RBL, RBR,
            PVL, PVR,
            BR, BL,
            QL, QR,
            ETC_DOTS,
            VERSION_,
        ])
)


PUNCT = r"([\.,\!\?\:…%s]+)" % (CONCAT_HYPHENS, )
SYM = r"([%s]+\>+|<->)" % (CONCAT_HYPHENS, )
AND = r"(?<=\w)[\\\/](?=\w)"

PUNCT_MATCH = (
    '|'.join(
        [
            SYM,
            PUNCT,
            AND
        ])
)

__all__ = ['TOKEN_MATCH', 'PUNCT_MATCH']