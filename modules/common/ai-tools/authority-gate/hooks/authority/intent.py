"""Read which gated actions a prompt or an assistant offer asks for."""

from __future__ import annotations

import re

from .grants import (
    ACTIVATE,
    APPROVE,
    DELETE,
    FORCE_PUSH,
    MERGE,
    PUBLISH,
    PUSH,
    RELEASE,
    REQUEST_CHANGES,
    REVIEW_DRAFT,
)

# Patterns run per clause; a negation earlier in the same clause revokes the
# grant instead.
CLAUSE_SPLIT = re.compile(r"[.!?;,:\n]+|\bbut\b|\bthen\b|\bafter that\b", re.IGNORECASE)
NEGATION_TERMS = (
    r"don'?t|do\s+not|never|no\s+need\s+to|not\s+yet|without|avoid|stop|"
    r"hold\s+off(?:\s+on)?|refrain\s+from|shouldn'?t|should\s+not|won'?t|will\s+not"
)
# In a user prompt, "I'll submit" means the user will do it.
NEGATION = re.compile(
    r"\b(?:"
    + NEGATION_TERMS
    + r"|i(?:'ll|\s+will|'m\s+going\s+to|\s+am\s+going\s+to))\b",
    re.IGNORECASE,
)
# In an assistant offer, "I'll push" announces the action instead.
OFFER_NEGATION = re.compile(r"\b(?:" + NEGATION_TERMS + r")\b", re.IGNORECASE)
READINESS = r"\bready\s+(?:to|for)\s+(?:squash[- ]|rebase[- ])?(?:merge|push|post|publish|submit)\b"
NOT_A_REQUEST_TERMS = (
    r"\b(?:merge|push)[- ]?ready\b|\bmergeable\b|"
    r"\b(?:before|after|once)\s+(?:we\s+|i\s+|you\s+|it'?s\s+)?(?:merg|push|post|publish)\w*|"
    r"\bmerge\s+(?:conflicts?|base|markers?|commits?|queue|requests?|strateg\w*|tool|driver)\b|"
    r"\bpush(?:ing)?\s+(?:back|notifications?)\b|\bmake\s+sure\b|"
    r"\b(?:the|a|an|your|my|last|latest|previous)\s+(?:push(?:es)?|merge|post|publish|"
    r"submit)\b|"
    r"\b(?:blog|forum|social)\s+post\b|\b(?:how|whether|when|where)\s+to\s+\w+|"
    r"\bexplain\b.*|\bwhat\s+(?:happens|would|does|did)\b.*|"
    r"\b(?:about|on|for|of|with|during|while|regarding)\s+(?:merg|push|post|publish)ing\b"
)
NOT_A_REQUEST = re.compile(READINESS + "|" + NOT_A_REQUEST_TERMS, re.IGNORECASE)
OFFER_NOT_A_REQUEST = re.compile(NOT_A_REQUEST_TERMS, re.IGNORECASE)
# Information questions ask about an action; they never authorize one.
QUESTION_CLAUSE = re.compile(
    r"^\s*(?:why|how|what|when|where|who|which|whose|did|does|was|were|is|are|"
    r"isn'?t|aren'?t|wasn'?t|have|has|had|do\s+(?:you|we|i|they)|"
    r"should\s+(?:i|we)|would\s+it|could\s+it)\b",
    re.IGNORECASE,
)
REVIEW_DRAFT_CONTEXT = re.compile(r"\b(?:pending|draft)\b", re.IGNORECASE)
# A draft pull request is still a public pull request, not a pending review.
DRAFT_PR = re.compile(
    r"\b(?:draft|pending)\s+(?:prs?|pull[- ]requests?|pr'?s)\b", re.IGNORECASE
)
PUBLISH_VERBS = re.compile(
    r"\b(?:post|publish|submit|leave|comment|reply|respond)\b", re.IGNORECASE
)
INTENT_PATTERNS: tuple[tuple[frozenset[str], re.Pattern[str]], ...] = tuple(
    (frozenset(keys), re.compile(pattern, re.IGNORECASE))
    for keys, pattern in (
        ({FORCE_PUSH}, r"\bforce[- ]?push(?:ing)?\b|\bpush\b.*--force\b"),
        ({PUSH}, r"\bpush(?:ing)?\b"),
        (
            {PUBLISH, PUSH},
            (
                r"\b(?:open|create|make|raise|submit|put\s+up)\b"
                r".{0,40}\b(?:prs?|pull[- ]requests?|pr'?s)\b"
            ),
        ),
        ({PUBLISH, PUSH}, r"\b(?:submit|link|push)\b.{0,30}\bstack\b"),
        (
            {PUBLISH},
            (
                r"\b(?:post|publish|submit)\b(?!-)(?=\s*$|\s+(?:it|this|that|them|these|"
                r"those|now|please|again|here|there|back|and|then|to|on|in|as|under|"
                r"results?|comments?|repl(?:y|ies)|reviews?|(?:summary|summaries)|findings|"
                r"updates?|notes?|(?:an?|the|my|our|your|these|those|both)\s+"
                r"(?:(?:draft|pending|inline|code|short|quick|brief|follow[- ]up|new|"
                r"final|updated|revised)\s+)*(?:prs?|pull\s+requests?|reviews?|"
                r"comments?|repl(?:y|ies)|notes?|(?:summary|summaries)|updates?|results?|"
                r"findings|suggestions?|issues?|release|description|body|fix))\b)"
            ),
        ),
        ({PUBLISH}, r"\b(?:comment|reply|respond)\s+(?:on|to|in|under|back)\b"),
        ({PUBLISH}, r"\bleave\s+(?:an?\s+|the\s+)?(?:comment|reply|note|review)\b"),
        (
            {PUBLISH},
            r"\bresolve\b.{0,30}\b(?:threads?|conversations?|comments?|feedback)\b",
        ),
        (
            {PUBLISH},
            (
                r"\b(?:update|edit|change|rewrite|reword|retitle|amend|revise|refresh)\b"
                r".{0,40}\b(?:prs?|pull[- ]requests?|descriptions?|titles?|issues?)\b"
            ),
        ),
        (
            {PUBLISH},
            r"\b(?:close|reopen)\b.{0,40}\b(?:prs?|pull[- ]requests?|issues?|#\d+)\b",
        ),
        (
            {PUBLISH},
            r"\b(?:mark|make|set|flip|move|convert)\b.{0,30}\b(?:ready|draft)\b|\bundraft\b",
        ),
        ({PUBLISH}, r"\b(?:add|remove|apply|set)\b.{0,20}\blabels?\b"),
        ({PUBLISH}, r"\b(?:open|create|file|raise|report)\b.{0,30}\bissues?\b"),
        ({PUBLISH}, r"\b(?:ping|mention|cc)\b.{0,30}@[\w-]+"),
        ({PUBLISH}, r"\b(?:create|make|share)\b.{0,20}\bgists?\b"),
        (
            {REVIEW_DRAFT},
            (
                r"\b(?:pending|draft)\s+(?:code\s+)?(?:suggestion\s+)?reviews?\b|"
                r"\breviews?\b.{0,40}\b(?:pending|draft)\b|\bleave\s+(?:it\s+)?pending\b"
            ),
        ),
        (
            {MERGE},
            (
                r"\b(?:squash[- ]|rebase[- ]|auto[- ]?)?merg(?:e|ing)\b(?=\s*$|\s+(?:it|this|"
                r"that|them|these|those|now|once|when|after|and|then|if|please|to|into|"
                r"everything|all|the\s+(?:prs?|pull\s+requests?|branch(?:es)?|stack|fix|"
                r"change|update)|prs?|pull\s+requests?|#\d+|stack)\b)"
            ),
        ),
        ({APPROVE}, r"\bapprove\b"),
        ({REQUEST_CHANGES}, r"\brequest(?:ing)?\s+changes\b"),
        (
            {RELEASE},
            (
                r"\b(?:cut|create|publish|draft|make|tag|do|ship)\b.{0,20}\breleases?\b|"
                r"\brelease\s+v?\d"
            ),
        ),
        (
            {DELETE},
            (
                r"\b(?:delete|remove|drop|prune)\b.{0,30}\b(?:remotes?|branch(?:es)?|"
                r"comments?|reviews?|releases?|tags?|repo(?:sitory)?|gists?|labels?|"
                r"prs?|pull[- ]requests?|issues?)\b"
            ),
        ),
        (
            {ACTIVATE},
            (
                r"\bnh\s+(?:os|home|darwin)\s+(?:switch|boot|test)\b|"
                r"\b(?:nixos|darwin)-rebuild\s+(?:switch|boot|test)\b|"
                r"\bhome-manager\s+switch\b|\bswitch\s+(?:to\s+)?(?:it|that|this|"
                r"(?:the\s+|my\s+)?(?:new\s+)?(?:config(?:uration)?|system|generation|"
                r"host|home|profile))\b|\bactivat(?:e|ing|ion)\b|\bdeploy(?:ing)?\b|"
                r"\brebuild\s+(?:and\s+)?(?:switch|boot|test)\b|"
                r"\bapply\b.{0,30}\b(?:config(?:uration)?|system|generation)\b"
            ),
        ),
    )
)
SESSION_SCOPE = re.compile(
    r"\b(?:for\s+the\s+rest\s+of\s+(?:this|the)\s+(?:session|conversation|thread)|"
    r"for\s+this\s+(?:session|conversation|thread)|from\s+now\s+on|going\s+forward|"
    r"until\s+i\s+say\s+otherwise|for\s+the\s+remainder|for\s+this\s+(?:task|work)|"
    r"as\s+needed|whenever\s+(?:you\s+)?(?:need|want)|without\s+asking|"
    r"don'?t\s+ask\s+(?:me\s+)?again|standing\s+authority)\b",
    re.IGNORECASE,
)
# Scope applies to the sentence that states it, not to the whole prompt.
SCOPE_SPLIT = re.compile(r"[.!?;\n]+")
AFFIRM = (
    r"yes|yep|yeah|yup|y|sure|ok|okay|alright|all\s+right|go\s+ahead|go\s+for\s+it|"
    r"do\s+(?:it|that|this|so)|please(?:\s+do(?:\s+(?:it|that|this|so))?)?|proceed|"
    r"confirm(?:ed)?|approved|ship\s+it|send\s+it|lgtm|sounds\s+good|looks\s+good|"
    r"that\s+works|works\s+for\s+me|correct|affirmative|let'?s\s+do\s+(?:it|that|this)|"
    r"let'?s\s+go|thanks|thank\s+you|fine|that'?s\s+fine"
)
AFFIRMATIVE = re.compile(r"^\s*(?:" + AFFIRM + r")\b", re.IGNORECASE)
# Only a bare confirmation grants what was just denied; a longer reply may
# acknowledge and move on.
AFFIRMATIVE_ONLY = re.compile(
    r"^\s*(?:" + AFFIRM + r")(?:[\s,.!]+(?:" + AFFIRM + r"))*[\s,.!]*$", re.IGNORECASE
)
KEEP_WORDING = re.compile(
    r"\bkeep\s+(?:that|the|this|my|your)\s+(?:wording|text|phrasing|sentence|line|"
    r"mention|reference)\b",
    re.IGNORECASE,
)
DEFERRAL = re.compile(
    r"\b(?:first|before\s+(?:that|you|we|doing|pushing|posting|merging|publishing)|"
    r"instead|now\s+let'?s|let'?s\s+first|wait|hold\s+(?:on|off)|actually|not\s+yet|"
    r"later)\b",
    re.IGNORECASE,
)
NEGATIVE_REPLY = re.compile(
    r"^\s*(?:no|nope|nah|not\s+yet|wait|hold\s+on|hold\s+off|stop|don'?t|do\s+not|"
    r"cancel|never\s*mind)\b",
    re.IGNORECASE,
)
OFFER_LEAD = re.compile(
    r"\b(?:want\s+me\s+to|should\s+i|shall\s+i|do\s+you\s+want|say\s+the\s+word|"
    r"say\s+which|let\s+me\s+know|if\s+you\s+want|i\s+can|i\s+could|i'?ll|i\s+will|"
    r"ready\s+to|next\s+step)\b",
    re.IGNORECASE,
)
SENTENCE_SPLIT = re.compile(r"(?<=[.!?])\s+|\n+")


def intent(text: str, *, offer: bool = False) -> tuple[set[str], set[str]]:
    """Return (granted, revoked) keys stated in text.

    An assistant offer skips the question filter, and there "I'll push" or
    "ready to push" name the offered action instead of deferring it.
    """
    granted: set[str] = set()
    revoked: set[str] = set()
    negation_pattern = OFFER_NEGATION if offer else NEGATION
    exclusions = OFFER_NOT_A_REQUEST if offer else NOT_A_REQUEST
    for clause in CLAUSE_SPLIT.split(text):
        if not offer and QUESTION_CLAUSE.search(clause):
            continue
        cleaned = exclusions.sub(" ", clause).strip()
        negation = negation_pattern.search(cleaned)
        draft_context = bool(
            REVIEW_DRAFT_CONTEXT.search(cleaned)
        ) and not DRAFT_PR.search(cleaned)
        for keys, pattern in INTENT_PATTERNS:
            for match in pattern.finditer(cleaned):
                found = set(keys)
                if (
                    draft_context
                    and PUBLISH in found
                    and PUBLISH_VERBS.search(match.group(0))
                ):
                    found = (found - {PUBLISH}) | {REVIEW_DRAFT}
                if negation and negation.start() < match.start():
                    revoked |= found
                else:
                    granted |= found
    return granted - revoked, revoked


def offer_text(message: str) -> str:
    """Return the sentences in which the assistant asked or offered to act."""
    return "\n".join(
        sentence
        for sentence in SENTENCE_SPLIT.split(message)
        if "?" in sentence or OFFER_LEAD.search(sentence)
    )
