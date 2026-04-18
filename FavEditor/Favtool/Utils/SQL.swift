//
//  File.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 17/11/22.
//

import Foundation
import SQLite
import SwiftUI

var cacheSettings = Table("cache_settings");

let id = Expression<Int64>("id");
let host = Expression<String>("host");
let hosti = Expression<Int>("host");
let transparency = Expression<Int>("transparency_analysis_result");
let iconPresent = Expression<String>("icon_is_in_cache");

func tryConnection() throws -> Connection {
    do {
        let dbPath = AppConfig.shared.dbURL.path
        let dataBase = try Connection(dbPath)
        print("Database connection established")
        return dataBase
    } catch {
        print("Database connection error: \(error)")
        throw error
    }
}

func removeSite (site : Site) -> Void{
    let row = cacheSettings.filter(host == site.host);
    do {
        try tryConnection().run(row.delete());
        print("func removeSite: row removed");
    } catch {
        print("func removeSite: \(error)");
    }
}

func prepareTable () throws -> AnySequence<Row> {
    let sequence : AnySequence<Row>;
    do {
        sequence = try tryConnection().prepare(cacheSettings);
        print("func prepareTable: table ready!");
        return sequence;
    } catch {
        print("func prepareTable: \(error)");
        throw error
    } 
}

func setTransparency (site : Site, value : Int) ->Void {
    do {
        let db = try tryConnection()
        let row = cacheSettings.filter(host == site.host)
        
        // Try to update first
        if try db.run(row.update(transparency <- 1)) == 0 {
            // If No row updated, insert it
            try db.run(cacheSettings.insert(host <- site.host, transparency <- 1, iconPresent <- "0"))
            print("func setTransparency: row inserted with transparency 1")
        } else {
            print("func setTransparency: transparency updated for \(site.host)")
        }
    } catch {
        print("func setTransparency error: \(error)")
    }
}

func numberOfSites () -> Int {
    do{
        var j = 0;
        for _ in try prepareTable() {
            j += 1;
        }
        return j;
    } catch {
        return 0
    }
}


func transparencyString (value : Int) -> String {
        return "透明，大 (全局强制)"
}


func setIconIsOnChache (site : Site) {
    do {
        let db = try tryConnection()
        let row = cacheSettings.filter(host == site.host);
        
        if try db.run(row.update(iconPresent <- "1", transparency <- 1)) == 0 {
            // Row didn't exist, insert it
            try db.run(cacheSettings.insert(host <- site.host, transparency <- 1, iconPresent <- "1"))
            print("func setIconIsOnChache: row inserted with transparency 1 (Large/Glass)");
        } else {
            print("func setIconIsOnChache: cache updated and transparency forced to 1 (Large/Glass)");
        }
    } catch {
        print("func setIconIsOnChache error: \(error)");
    }
}
