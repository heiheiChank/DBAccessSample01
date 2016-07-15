//
//  AddViewController.swift
//  DBAccessSample01
//
//  Created by guest on 2016/06/20.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit

class AddViewController: UIViewController {
    
    var delegate: Observable?

    @IBOutlet weak var gnoTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var accessIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        errorMessageLabel.text = ""
    }
    
    //**
    //** テキストフィールド編集終了時キーボードを閉じるデリゲートメソッド
    //**
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        gnoTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
        return true
    }
    
    //**
    //** エラーメッセージ表示メソッド
    //**
    private func showErrorMessage(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.errorMessageLabel.text = message
        }
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

    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)

    }
    @IBAction func add() {
        // テキストフィールドnilチェック
        guard let gnoText = gnoTextField.text else {
            let errorMessage = "学籍番号フィールド nilエラー発生"
            showErrorMessage(errorMessage)
            return
        }
        guard let nameText = nameTextField.text else {
            let errorMessage = "氏名フィールド nilエラー発生"
            showErrorMessage(errorMessage)
            return
        }
        
        // 入力欄が未入力ならばエラー出力して終了
        if gnoText == "" || nameText == "" {
            let errorMessage = "未入力エラー発生"
            showErrorMessage(errorMessage)
            return
        }
        
        // 追加データ作成
        let studentDict = ["gno" : gnoText, "name" : nameText]
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
        request.HTTPMethod = "POST"
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
            // ListViewControllerのテーブルビューの更新を行う
            self.delegate?.updateTableView()
            //　自分自身のビューコントローラーを引っ込める(dismiss)
            self.dismissViewControllerAnimated(true, completion: nil)
            
        }
    }
}
