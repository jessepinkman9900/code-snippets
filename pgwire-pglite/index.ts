import { PGlite } from '@electric-sql/pglite'
import { PGLiteSocketServer } from '@electric-sql/pglite-socket'

// Create a PGlite instance
const db = await PGlite.create({
    dataDir: 'memory://'
})

// Create and start a socket server
const server = new PGLiteSocketServer({
  db,
  port: 5432,
})

await server.start()
console.log('Server started on 127.0.0.1:5432')

// Handle graceful shutdown
process.on('SIGINT', async () => {
  await server.stop()
  await db.close()
  console.log('Server stopped and database closed')
  process.exit(0)
})
