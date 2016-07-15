//
//  UpdateViewController.swift
//  DBAccessSample01
//
//  Created by guest on 2016/06/24.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit

class UpdateViewController: UIViewController {
    
    var delegate: Observable?
    var gnoText = ""
    var nameText = ""
    
    @IBOutlet weak var gnoLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var accessIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        gnoLabel.text = gnoText
        nameTextField.text = nameText
        errorMessageLabel.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        return true
    }
    
    //** エラーメッセージ表示メソッド
    private func showErrorMessage(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.errorMessageLabel.text = message
        }
    }
    
    @IBAction func cancel() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func update() {
        // テキストフィールドnilチェック
        guard let updatedNameText = nameTextField.text else {
            let errorMessage = "氏名フィールド nilエラー発生"
            showErrorMessage(errorMessage)
            return
        }
        
        // 入力欄が未入力ならばエラー出力して終了
        if updatedNameText == "" {
            let errorMessage = "未入力エラー発生"
            showErrorMessage(errorMessage)
            return
        }
        
        // 更新データ作成
        let studentDict = ["gno" : gnoText, "name" : updatedNameText]
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
        
        // インジケータ開始
        accessIndicator.startAnimating()
        
        // URL変換
        guard let url = NSURL(string: "http://localhost/15cm0106/students.php") else {
            let errorMessage = "url変換エラー発生"
            showErrorMessage(errorMessage)
            return
        }
        
        // URLRequest作成
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.HTTPBody = bodyData
        
        // NSURLSessionオブジェクト初期化とタスクの設定
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: sessionHandler)
        
        // タスク実行
        task.resume()
    }
    
    //**
    //** NSURLSessionクラスdataTaskWithRequestメソッドの引数completionHandlerメソッド
    //**
    private func sessionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
        
        // インジケータ停止
        dispatch_async(dispatch_get_main_queue()) {
            self.accessIndicator.stopAnimating()
        }
        
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
            self.delegate?.updateTableView()
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    @IBAction func delete() {
        // テキストフィールドnilチェック
        guard let updatedNameText = nameTextField.text else {
            let errorMessage = "氏名フィールド nilエラー発生"
            showErrorMessage(errorMessage)
            return
        }
        
        // 入力欄が未入力ならばエラー出力して終了
        if updatedNameText == "" {
            let errorMessage = "未入力エラー発生"
            showErrorMessage(errorMessage)
            return
        }
        
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
        
        // インジケータ開始
        accessIndicator.startAnimating()
        
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
        let task = session.dataTaskWithRequest(request, completionHandler: sessionHandler)
        
        // タスク実行
        task.resume()
    }
}