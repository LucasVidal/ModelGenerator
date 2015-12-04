//: Playground - noun: a place where people can play

import UIKit


postfix operator |< { } //Appends a \n
postfix func |< (string: String) -> String { return string + "\n" }

prefix operator >| { } //Prepends a \t
prefix func >| (string: String) -> String { return "\t" + string }

infix operator >| { associativity left precedence 200 } //Prepends a \t as many as "left times"
//TODO: get sober later and code this.
//func >| (times: Int, string: String) -> String {}

infix operator <+  { associativity left precedence 100 } //Appends string adding a \n sufix
func <+ (inout left: String, right: String) { left += right + "\n" }


indirect enum MetaModelType {
    case String, Int, Double, Bool, Array(MetaModelType), Optional(MetaModelType)

    var argoOperator: Swift.String {
        switch self {
        case Optional(_): return "<|?"
        default: return "<|"
        }
    }

    var typeRepresentation: Swift.String {
        switch self {
        case String: return "String"
        case Int: return "Int"
        case Double: return "Double"
        case Bool: return "Bool"
        case Array(let t): return "[\(t.typeRepresentation)]"
        case Optional(let t): return "\(t.typeRepresentation)?"
        }
    }
}

struct MetaModel {
    let name: String
    let properties: [String : MetaModelType]
}

let p = MetaModelType.Optional(.Array(.Optional(.String)))

let customer = MetaModel(name: "Customer", properties:
    [
        "name" : .String,
        "points" : .Int,
        "active" : .Bool,
        "pets" : .Array(.String),
        "address" : .Optional(.String)
    ])

class ArgoBuilder {
    let model: MetaModel
    init(model: MetaModel) {
        self.model = model
    }

    var def = ""

    var header: String {
        return "import Argo\nimport Curry\n"
    }

    var classDefinition: String {
        return "struct \(model.name) {\n" + propertyDefinition + "}"
    }

    var propertyDefinition: String {
        var props = ""
        for (name, type) in model.properties {
            props <+ >|"let \(name): \(type.typeRepresentation)"
        }
        return props
    }

    var mappingDefinition: String {
        var mapping = "extension \(model.name): Decodable"|<
        mapping <+ >|"static func decode(j: JSON) -> Decoded<\(model.name)> {"|<
        mapping <+ >|(>|"return curry\(model.name).init")
        for (index, (name, type)) in model.properties.enumerate() {
            let rune = index == 0 ? "<^>" : "<*>"
            mapping <+ >|(>|(>|("\(rune) j \(type.argoOperator) \"\(name)\"")))
        }
        mapping <+ (((>|"}")|<) + (>|"}")) //hell yeah!
        return mapping
    }

    func build() -> String {
        def <+ header
        def <+ classDefinition
        def <+ mappingDefinition

        return def
    }
}

let builder = ArgoBuilder(model: customer)

func suma(first: Int, second: Int) -> Int {
    return first + second
}

func curry<T, U, V>(f : (T, U) -> V) -> T -> U -> V {
    return { x in { y in f(x, y) } }
}


let f = curry(suma)

let g = f(2)

let result = g(3)

print(builder.build())


