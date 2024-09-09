import Vapor

func clientRoutes(_ app: Application) throws {
    app.get { req in
        req.fileio.streamFile(at: app.directory.publicDirectory + "index.html")
    }
}
