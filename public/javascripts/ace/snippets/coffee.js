ace.define("ace/snippets/coffee",["require","exports","module"],function(e,t,n){t.snippetText="# Closure loop\nsnippet forindo\n	for ${1:name} in ${2:array}\n		do ($1) ->\n			${3:// body}\n# Array comprehension\nsnippet fora\n	for ${1:name} in ${2:array}\n		${3:// body...}\n# Object comprehension\nsnippet foro\n	for ${1:key}, ${2:value} of ${3:object}\n		${4:// body...}\n# Range comprehension (inclusive)\nsnippet forr\n	for ${1:name} in [${2:start}..${3:finish}]\n		${4:// body...}\nsnippet forrb\n	for ${1:name} in [${2:start}..${3:finish}] by ${4:step}\n		${5:// body...}\n# Range comprehension (exclusive)\nsnippet forrex\n	for ${1:name} in [${2:start}...${3:finish}]\n		${4:// body...}\nsnippet forrexb\n	for ${1:name} in [${2:start}...${3:finish}] by ${4:step}\n		${5:// body...}\n# Function\nsnippet fun\n	(${1:args}) ->\n		${2:// body...}\n# Function (bound)\nsnippet bfun\n	(${1:args}) =>\n		${2:// body...}\n# Class\nsnippet cla class ..\n	class ${1:`substitute(Filename(), '\\(_\\|^\\)\\(.\\)', '\\u\\2', 'g')`}\n		${2}\nsnippet cla class .. constructor: ..\n	class ${1:`substitute(Filename(), '\\(_\\|^\\)\\(.\\)', '\\u\\2', 'g')`}\n		constructor: (${2:args}) ->\n			${3}\n\n		${4}\nsnippet cla class .. extends ..\n	class ${1:`substitute(Filename(), '\\(_\\|^\\)\\(.\\)', '\\u\\2', 'g')`} extends ${2:ParentClass}\n		${3}\nsnippet cla class .. extends .. constructor: ..\n	class ${1:`substitute(Filename(), '\\(_\\|^\\)\\(.\\)', '\\u\\2', 'g')`} extends ${2:ParentClass}\n		constructor: (${3:args}) ->\n			${4}\n\n		${5}\n# If\nsnippet if\n	if ${1:condition}\n		${2:// body...}\n# If __ Else\nsnippet ife\n	if ${1:condition}\n		${2:// body...}\n	else\n		${3:// body...}\n# Else if\nsnippet elif\n	else if ${1:condition}\n		${2:// body...}\n# Ternary If\nsnippet ifte\n	if ${1:condition} then ${2:value} else ${3:other}\n# Unless\nsnippet unl\n	${1:action} unless ${2:condition}\n# Switch\nsnippet swi\n	switch ${1:object}\n		when ${2:value}\n			${3:// body...}\n\n# Log\nsnippet log\n	console.log ${1}\n# Try __ Catch\nsnippet try\n	try\n		${1}\n	catch ${2:error}\n		${3}\n# Require\nsnippet req\n	${2:$1} = require '${1:sys}'${3}\n# Export\nsnippet exp\n	${1:root} = exports ? this\n",t.scope="coffee"})