import FoundationModels

extension GrammarConfig {
    public static func fromType<T: Generable>(_ type: T.Type) -> Self {
        let schema = T.generationSchema.debugDescription
        let result = GrammarConfig.jsonSchema(schema: schema)
        return result
    }
}
