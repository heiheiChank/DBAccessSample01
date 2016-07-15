//
//  ListViewController.swift
//  DBAccessSample01
//
//  Created by guest on 2016/06/17.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit

protocol Observable {
    func updateTableView()
}

class ListViewController: UITableViewController, UISearchBarDelegate, Observable {
    
    private var studentArray: [Student]?
    private var httpErrorMessage = ""
    private var searchBarText = ""
    private var gnoText = ""
    private var nameText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // self.tableView.registerClass(Cell.self, forCellReuseIdentifier: "Cell")
        // コードで値を入力した時にしか書いてはいけない
        // JSON取得完了まではテーブルビューセルを選択不可にする
        //tableView.allowsSelection = false
        
        //UISearchBarDelegateのデリゲート
        
        // JSON取得
        fetchJSON()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    //**
    //** Observableプロトコル　プロトコルメソッド
    //**
    func updateTableView() {
        // JSON取得完了まではテーブルビューセルを選択不可にする
        tableView.allowsSelection = false
        
        // JSON取得
        fetchJSON()
    }

    
    //**
    //** インジケータ開始メソッド
    //**
    private func startProcessing() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    //**
    //** インジケータ停止メソッド
    //**
    private func stopProcessing() {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.tableView.reloadData() // テーブルビューの再描画
        }
    }
    
    //**
    //** JSON取得メソッド
    //**
    private func fetchJSON() {
        
        // studentArrayの初期化
        studentArray = nil
        
        // テーブルビュー1行目メッセージの初期化
        httpErrorMessage = ""
        
        // インジケータ開始
        startProcessing()
        
        // URL文字列作成 20160704修正
        var urlString = "http://localhost/15cm0106/students.php"
        // 検索条件等付加したい場合は上記URLの後に文字列を追加すれば、GETメソッドでリクエストできる
        // （例．?condition=文字列
        if searchBarText != "" {
            urlString = urlString + "?condition=" + searchBarText
        }
        
        // URL変換
        guard let url = NSURL(string: urlString) else {
            httpErrorMessage = "url変換エラー発生"
            return
        }
        
        // URLRequest作成
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // NSURLSessionオブジェクト初期化とタスクの設定
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: sessionHandler)
        
        // タスク実行
        task.resume()
        
    }
    
    //**
    //** UISearchBarDelegate デリゲートメソッド
    //**
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        //URLエンコーディング（文字列エスケープ処理)
        searchBarText = searchBar.text!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        // JSON再取得
        fetchJSON()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.resignFirstResponder()
        //URLエンコーディング（文字列エスケープ処理)
        searchBarText = searchBar.text!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        // JSON再取得
        fetchJSON()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBarText = "" // 20160704追加
        // JSON再取得
        fetchJSON()
    }
    
    //**
    //** NSURLSessionクラスdataTaskWithRequestメソッドの引数completionHandlerメソッド
    //**
    private func sessionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
        
        // インジケータ停止
        dispatch_async(dispatch_get_main_queue()) {
            self.stopProcessing()
        }
        
        //
        // エラーフィルタリング
        //
        // サーバ接続不可能エラー
        if let requestError = error {
            let errorMessage = "HTTPエラー発生： \(requestError.localizedDescription)"
            print(errorMessage)
            showErrorMessage(errorMessage)
            return
        }
        
        // レスポンスnilエラー
        guard let urlResponse = response else {
            let errorMessage = "HTTPエラー発生： urlResponse nil"
            showErrorMessage(errorMessage)
            return
        }
        
        // HTTP以外のプロコルによるエラー
        guard let httpResponse = urlResponse as? NSHTTPURLResponse else {
            let errorMessage = "HTTPエラー発生： urlResponseのクラスは \(urlResponse.dynamicType)"
            print(errorMessage)
            showErrorMessage(errorMessage)
            return
        }
        
        // ステータスコードは200番台以外のエラー
        let statusCode = httpResponse.statusCode
        if statusCode < 200 || statusCode >= 300 {
            let errorMessage = "HTTPエラー発生： \(statusCode)"
            showErrorMessage(errorMessage)
        }
        
        // レスポンスデータnilエラー
        guard let responseData = data else {
            let errorMessage = "responseDataエラー発生"
            showErrorMessage(errorMessage)
            return
        }
        
        // レスポンスデータ0件エラー
        if responseData.length == 0 {
            let errorMessage = "responseData0件"
            showErrorMessage(errorMessage)
            return
        }
        
        
        // エラーなし
        // JSONシリアライズ
        var jsonArray = [AnyObject]()
        do {
            jsonArray = try NSJSONSerialization.JSONObjectWithData(
                responseData,
                options: NSJSONReadingOptions.MutableContainers) as? [AnyObject] ?? []
        } catch (let jsonError) {
            let errorMessage = "JSONシリアライズエラー発生: \(jsonError)"
            print("\(jsonError)")
            showErrorMessage(errorMessage)
        }
        
        // JSONパース
        studentArray = parseJSON(jsonArray)
        
        // テーブルビュー再表示
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.allowsSelection = true
            self.tableView.reloadData()
        }
    }
    
    private func sessionHandler2(data: NSData?, response: NSURLResponse?, error: NSError?) {
        
        //
        // エラーフィルタリング
        //
        // サーバ接続不可能エラー
        if let requestError = error {
            let errorMessage = "HTTPエラー発生: \(requestError.localizedDescription)"
            showErrorMessage(errorMessage)
            return
        }
        
        // レスポンスnilエラー
        guard let urlResponse = response else {
            let errorMessage = "HTTPエラー発生: urlResponse nil"
            showErrorMessage(errorMessage)
            return
        }
        
        // HTTP以外のプロコルによるエラー
        guard let httpResponse = urlResponse as? NSHTTPURLResponse else {
            let errorMessage = "HTTPエラー発生: urlResponseのクラスは\(urlResponse.dynamicType)"
            showErrorMessage(errorMessage)
            return
        }
        
        // ステータスコードが200番台以外のエラー
        let statusCode = httpResponse.statusCode
        if statusCode < 200 || statusCode >= 300 {
            let errorMessage = "HTTPエラー発生:（\(statusCode)）"
            showErrorMessage(errorMessage)
            return
        }
        
        // レスポンスデータnilエラー
        guard let responseData = data else {
            let errorMessage = "responseData nilエラー発生"
            showErrorMessage(errorMessage)
            return
        }
        
        // SQLエラー
        if responseData.length != 0 { // 今回はSQLエラーが発生した時にresponseData長が1以上になる
            guard let message = NSString(data: responseData, encoding: NSUTF8StringEncoding) else {
                let errorMessage = "responseData -> String変換エラー発生"
                showErrorMessage(errorMessage)
                return
            }
            let errorMessage = "SQLエラー発生: \(message)"
            showErrorMessage(errorMessage)
            return
        }
        
        //
        // エラーなし
        //
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.allowsSelection = true
            self.tableView.reloadData()
        }
    }

    
    //** エラーメッセージ表示メソッド
    private func showErrorMessage(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.httpErrorMessage = message
            self.tableView.reloadData()
        }
    }
    
    //** 学生データJSONパースメソッド
    private func parseJSON(json: [AnyObject]) -> [Student] {
        return json.map { result in
            guard let gno = result["gno"] as? String else { fatalError("Parse error!") }
            guard let name = result["name"] as? String else { fatalError("Parse error!") }
            return Student(gno: gno, name: name)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        if (httpErrorMessage == "") {
            if let array = studentArray {
                return array.count
            } else {
                return 1 // Loading...
            }
        } else {
            return 1 // HTTP error message
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! Cell
        
        // Configure the cell...
        
        if (httpErrorMessage == "") {
            if let array = studentArray {
                let student = array[indexPath.row]
                gnoText = student.gno
                nameText = student.name
            } else {
                gnoText = "Loading..."
                nameText = "Loading..."
            }
        } else {
            gnoText = httpErrorMessage
        }
        cell.gnoLabel.text = gnoText
        cell.nameLabel.text = nameText
                
        return cell
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // アニメーションの作成
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = 1.0
        animation.beginTime = CACurrentMediaTime() + 0.20
        
        // アニメーションが開始される前からアニメーション開始地点に表示
        animation.fillMode = kCAFillModeBackwards
        
        // セルのLayerにアニメーションを追加
        cell.layer.addAnimation(animation, forKey: nil)
        
        // アニメーション終了後は元のサイズになるようにする
        cell.layer.transform = CATransform3DIdentity

    }
// 横スクロール削除
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let array = studentArray
        let student = array![indexPath.row]
        gnoText = student.gno
        cansel()
        self.studentArray?.removeAtIndex(indexPath.row)
            }
    
    private func cansel() {
        // テキストフィールドnilチェック
//        guard let updatedNameText = nameText else {
//            let errorMessage = "氏名フィールド nilエラー発生"
//            showErrorMessage(errorMessage)
//            return
//        }
//        
//        // 入力欄が未入力ならばエラー出力して終了
//        if updatedNameText == "" {
//            let errorMessage = "未入力エラー発生"
//            showErrorMessage(errorMessage)
//            return
//        }
        
        // 更新データ作成
        let studentDict = ["gno" : gnoText]
        let studentArray = [studentDict] as AnyObject
          // JSONシリアライズ
        var bodyData = NSData()
        do {
            bodyData = try NSJSONSerialization.dataWithJSONObject(
                studentArray,
                options: NSJSONWritingOptions.PrettyPrinted)
        } catch (let jsonError) {
            let errorMessage = "JSONシリアライズエラー発生: \(jsonError)"
            showErrorMessage(errorMessage)
        }
        
        // URL変換
        guard let url = NSURL(string: "http://localhost/15cm0106/students.php") else {
            let errorMessage = "url変換エラー発生"
            showErrorMessage(errorMessage)
            return
        }
        
        // URLRequest作成
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.HTTPBody = bodyData
        
        // NSURLSessionオブジェクト初期化とタスクの設定
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: sessionHandler2)
        
        // タスク実行
        task.resume()
        
    }
    
    // MARK: - Table view data source

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        switch segue.destinationViewController {
        case let addVC as AddViewController:
            addVC.delegate = self
        case let updateVC as UpdateViewController:
            let indexPath = tableView.indexPathForSelectedRow
            let student = studentArray![indexPath!.row]
            updateVC.gnoText = student.gno
            updateVC.nameText = student.name
            updateVC.delegate = self
        default:
            print("Segue has no parameters.")
        }
    }
    
}
