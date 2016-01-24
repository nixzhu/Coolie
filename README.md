
# Coolie([苦力](https://zh.wikipedia.org/wiki/%E8%8B%A6%E5%8A%9B))

Coolie parse a JSON file to generate models (& their constructors).

## Requirements

Swift 2.1

## Example

`test.json`:

``` json
{
  "name": "NIX",
  "detail": {
    "age": 18,
    "gender": null,
    "is_dog_lover": true,
    "is_cat_lover": false,
    "skills": [
      "Swift on iOS",
      "C on Linux"
    ],
    "introduction": "爱你所爱，恨你所恨。"
  },
  "projects": [
    {
      "name": "Navi",
      "url": "https://github.com/nixzhu/Navi"
    },
    {
      "name": "Coolie",
      "url": "https://github.com/nixzhu/Coolie"
    }
  ]
}
```

Build coolie & run:

``` bash
$ xcrun swiftc Sources/*.swift -o coolie
$ ./coolie test.json User
```

It will generate:

``` swift
struct User {
	struct Detail {
		let age: Int
		let gender: UnknownType?
		let introduction: String
		let isCatLover: Bool
		let isDogLover: Bool
		let skills: [String]
		static func fromJSONDictionary(info: [String: AnyObject]) -> Detail? {
			guard let age = info["age"] as? Int else { return nil }
			let gender = info["gender"] as? UnknownType
			guard let introduction = info["introduction"] as? String else { return nil }
			guard let isCatLover = info["is_cat_lover"] as? Bool else { return nil }
			guard let isDogLover = info["is_dog_lover"] as? Bool else { return nil }
			guard let skills = info["skills"] as? [String] else { return nil }
			return Detail(age: age, gender: gender, introduction: introduction, isCatLover: isCatLover, isDogLover: isDogLover, skills: skills)
		}
	}
	let detail: Detail
	let name: String
	struct Project {
		let name: String
		let url: String
		static func fromJSONDictionary(info: [String: AnyObject]) -> Project? {
			guard let name = info["name"] as? String else { return nil }
			guard let url = info["url"] as? String else { return nil }
			return Project(name: name, url: url)
		}
	}
	let projects: [Project]
	static func fromJSONDictionary(info: [String: AnyObject]) -> User? {
		guard let detailJSONDictionary = info["detail"] as? [String: AnyObject] else { return nil }
		guard let detail = Detail.fromJSONDictionary(detailJSONDictionary) else { return nil }
		guard let name = info["name"] as? String else { return nil }
		guard let projectsJSONArray = info["projects"] as? [[String: AnyObject]] else { return nil }
		let projects = projectsJSONArray.map({ Project.fromJSONDictionary($0) }).flatMap({ $0 })
		return User(detail: detail, name: name, projects: projects)
	}
}
```

Pretty cool, ah?

## Contact

NIX [@nixzhu](https://twitter.com/nixzhu)

## License

Coolie is available under the [MIT License][mitLink]. See the LICENSE file for more info.
[mitLink]:http://opensource.org/licenses/MIT
