#!/bin/bash

echo "# Coolie([苦力](https://zh.wikipedia.org/wiki/%E8%8B%A6%E5%8A%9B))"
echo
echo "Coolie parse a JSON file to generate models (& their constructors)."
echo
echo "苦力有很强的类型推断能力，除了能识别 URL 或常见 Date 类型，还能自动推断数组类型（并进行类型合并），你可从下面的例子看出细节。"
echo
echo "[Working with JSON in Swift](https://developer.apple.com/swift/blog/?id=37)"
echo
echo "中文介绍：[制作一个苦力](https://github.com/nixzhu/dev-blog/blob/master/2016-06-29-coolie.md)"
echo
echo "## Requirements"
echo
echo "Swift 3.0"
echo
echo "## Example"
echo
echo "\`test.json\`:"
echo
echo "\`\`\` json"
cat ./test.json
echo "\`\`\`"
echo
echo "Build coolie & run:"
echo
echo "\`\`\` bash"
echo "$ swift build"
echo "$ ./.build/debug/coolie -i test.json --model-name User --argument-label json --parameter-name info"
echo "\`\`\`"
echo
echo "It will generate:"
echo
echo "\`\`\` swift"
./.build/debug/coolie -i test.json --model-name User --argument-label json --parameter-name info
echo "\`\`\`"
echo
echo "You may need some date formatters:"
echo
echo "\`\`\` swift"
cat ./date_formatters.txt
echo "\`\`\`"
echo
echo "Use \`--iso8601-date-formatter-name\` or \`--date-only-date-formatter-name\` can set the name of the date formatter."
echo
echo "Pretty cool, ah?"
echo "Now you can modify the models (the name of properties or their type) if you need."
echo
echo "You can specify constructor name, argument label, or json dictionary name, like following command:"
echo
echo "\`\`\` bash"
echo "$ ./.build/debug/coolie -i test.json --model-name User --constructor-name create --argument-label with --parameter-name json --json-dictionary-name JSONDictionary"
echo "\`\`\`"
echo
echo "It will generate:"
echo
echo "\`\`\` swift"
./.build/debug/coolie -i test.json --model-name User --constructor-name create --argument-label with --parameter-name json --json-dictionary-name JSONDictionary
echo "\`\`\`"
echo
echo "You may need \`typealias JSONDictionary = [String: Any]\`."
echo
echo "Or the way I like with throws:"
echo
echo "\`\`\` bash"
echo "$ ./.build/debug/coolie -i test.json --model-name User --argument-label with --parameter-name json --json-dictionary-name JSONDictionary --throws"
echo "\`\`\`"
echo
echo "It will generate:"
echo
echo "\`\`\` swift"
./.build/debug/coolie -i test.json --model-name User --argument-label with --parameter-name json --json-dictionary-name JSONDictionary --throws
echo "\`\`\`"
echo
echo "Of course, you need to define \`ParseError\`:"
echo
echo "\`\`\` swift"
cat parse_error.txt
echo "\`\`\`"
echo
echo "If you need class model, use the following command:"
echo
echo "\`\`\` bash"
echo "$ ./.build/debug/coolie -i test.json --model-name User --model-type class"
echo "\`\`\`"
echo
echo "\`\`\` swift"
./.build/debug/coolie -i test.json --model-name User --model-type class
echo "\`\`\`"
echo
echo "Also \`--argument-label\`, \`--parameter-name\` and \`--json-dictionary-name\` options are available for class."
echo
echo "If you need more information for debug, append a \`--debug\` option in all the commands."
echo
echo "## Contact"
echo
echo "NIX [@nixzhu](https://twitter.com/nixzhu)"
echo
echo "## License"
echo
echo "Coolie is available under the [MIT License][mitLink]. See the LICENSE file for more info."
echo "[mitLink]:http://opensource.org/licenses/MIT"

