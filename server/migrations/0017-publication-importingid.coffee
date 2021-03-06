class Migration extends Document.MajorMigration
  name: "Renaming temporaryFilename field to importingId"

  forward: (document, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema, 'importing.temporaryFilename': {$exists: true}}, {importing: 1}, (document) =>
      updateQuery =
        $set:
          _schema: newSchema
        $unset: {}

      for importing, i in document.importing or []
        continue if importing.importingId or not importing.temporaryFilename

        updateQuery.$set["importing.#{ i }.importingId"] = importing.temporaryFilename
        updateQuery.$unset["importing.#{ i }.temporaryFilename"] = ''

      count += collection.update {_schema: currentSchema, _id: document._id, importing: document.importing}, updateQuery

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema, 'importing.importingId': {$exists: true}}, {importing: 1}, (document) =>
      updateQuery =
        $set:
          _schema: oldSchema
        $unset: {}

      for importing, i in document.importing or []
        continue if importing.temporaryFilename or not importing.importingId

        updateQuery.$set["importing.#{ i }.temporaryFilename"] = importing.importingId
        updateQuery.$unset["importing.#{ i }.importingId"] = ''

      count += collection.update {_schema: currentSchema, _id: document._id, importing: document.importing}, updateQuery

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Publication.addMigration new Migration()
