import Async

public struct Aggregate<C: Codable>: Command {
    let targetCollection: MongoCollection<C>
    
    public let aggregate: String
    public var pipeline: [AggregationPipeline.Stage]
    public var cursor: CursorOptions
    public var maxTimeMS: UInt32?
    public var bypassDocumentValidation: Bool?
    public var readConcern: ReadConcern?
    public var collation: Collation?
    
    static var writing: Bool { return true }
    static var emitsCursor: Bool { return true }
    
    public init(pipeline: AggregationPipeline, on collection: Collection<C>) {
        self.aggregate = collection.name
        self.targetCollection = collection
        self.pipeline = pipeline.stages
        self.cursor = CursorOptions()
        
        // Collection defaults
        self.readConcern = collection.default.readConcern
        self.collation = collection.default.collation
    }
    
    public func execute(on connection: DatabaseConnection) -> Cursor<C> {
        let cursor = Cursor(collection: aggregate, connection: connection)
        
        connection.execute(self, expecting: Reply.Cursor.self).do { spec in
            cursor.initialize(to: spec.cursor)
        }.catch(cursor.pushStream.error)
        
        return cursor
    }
}

public struct CursorOptions: Codable {
    var batchSize: Int32 = 100
}