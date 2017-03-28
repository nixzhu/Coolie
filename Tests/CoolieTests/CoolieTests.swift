import XCTest
@testable import Coolie

class CoolieTests: XCTestCase {

    func testStruct() {
        let jsonString = "{\"name\": \"NIX\", \"age\": 18}"
        let coolie = Coolie(jsonString)
        let _model = coolie.generateModel(
            name: "User",
            type: .struct,
            argumentLabel: Coolie.Config.argumentLabel,
            constructorName: Coolie.Config.constructorName,
            jsonDictionaryName: Coolie.Config.jsonDictionaryName,
            debug: Coolie.Config.debug
        )
        let model = _model ?? ""
        XCTAssert(!model.isEmpty, "Model is emtpy!")
        let expectedModel = "struct User {\n\tlet age: Int\n\tlet name: String\n\tinit?(_ json: [String: Any]) {\n\t\tguard let age = json[\"age\"] as? Int else { return nil }\n\t\tguard let name = json[\"name\"] as? String else { return nil }\n\t\tself.age = age\n\t\tself.name = name\n\t}\n}"
        print(model)
        print(expectedModel)
        XCTAssertEqual(model, expectedModel)
    }

    static var allTests : [(String, (CoolieTests) -> () throws -> Void)] {
        return [
            ("testStruct", testStruct),
        ]
    }
}
