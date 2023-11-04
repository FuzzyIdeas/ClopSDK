import Foundation

class MetaQuery {
    init(scopes: [String], queryString: String, sortBy: [NSSortDescriptor] = [], handler: @escaping ([NSMetadataItem]) -> Void) {
        let q = NSMetadataQuery()
        q.searchScopes = scopes
        q.predicate = NSPredicate(fromMetadataQueryString: queryString)
        q.sortDescriptors = sortBy

        q.start()
        query = q
        observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: q, queue: nil) { [weak self] notification in
            guard let query = notification.object as? NSMetadataQuery,
                  let items = query.results as? [NSMetadataItem]
            else {
                return
            }
            q.stop()
            if let observer = self?.observer {
                NotificationCenter.default.removeObserver(observer)
            }
            handler(items)
        }
    }

    deinit {
        query.stop()
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    let query: NSMetadataQuery
    var observer: NSObjectProtocol?
}

extension NSMetadataItem {
    var path: String {
        (value(forAttribute: NSMetadataItemPathKey) as? String) ?? ""
    }
}

func findClopApp(_ handler: @escaping (URL?) -> Void) -> MetaQuery {
    let sortByLastUsedDateAdded = [
        NSSortDescriptor(key: NSMetadataItemLastUsedDateKey, ascending: false),
        NSSortDescriptor(key: NSMetadataItemDateAddedKey, ascending: false),
    ]
    return MetaQuery(
        scopes: ["/"], queryString: "kMDItemContentTypeTree == 'com.apple.application-bundle' && kMDItemFSName == 'Clop.app'", sortBy: sortByLastUsedDateAdded
    ) { items in
        guard let item = items.first(where: { item in item.path.hasSuffix("/Setapp/Clop.app") }) ?? items.first(where: { item in item.path.hasSuffix("/Applications/Clop.app") }) ?? items.first,
              let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL
        else {
            return
        }
        handler(url)
    }
}
