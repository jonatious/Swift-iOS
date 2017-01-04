//
//  FreebieTableViewController.swift
//  FreebieFinder
//
//  Created by ubicomp3 on 9/26/16.
//  Copyright © 2016 ubicomp3. All rights reserved.
//

import UIKit
import Firebase

class FreebieTableViewController: UITableViewController, UIViewControllerPreviewingDelegate {

    var ref : FIRDatabaseReference!
    var freebies = [Freebie]()
    var myFreebies = [Freebie]()
    var selectedFreebie: Freebie?
    var Categories = ["Food", "T-Shirt", "Other"]
    var freebiesByCat = [String: [Freebie]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.tableView.backgroundColor = UIColor.init(red: 90/255, green: 145/255, blue: 190/255, alpha: 1)
        self.tabBarController?.tabBar.tintColor = UIColor.white
        self.tabBarController?.tabBar.unselectedItemTintColor = UIColor.init(red: 24/255, green: 36/255, blue: 59/255, alpha: 1)
        
        if traitCollection.forceTouchCapability == .available
        {
            registerForPreviewing(with: self, sourceView: view)
            let NotName = Notification.Name("load")
            NotificationCenter.default.addObserver(self, selector: #selector(self.loadList),name: NotName, object: nil)
        }
        
        self.refreshControl?.addTarget(self, action: #selector(self.refresh(sender:)), for: UIControlEvents.valueChanged)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        self.selectedFreebie = nil
        loadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Actions
    
    @IBAction func logoutBtn(_ sender: UIBarButtonItem) {
        SignedInUser.sharedInstance.signedIn = false;
        SignedInUser.sharedInstance.userName = ""
        let vc : UIViewController = self.storyboard!.instantiateViewController(withIdentifier: "ViewControllerid") ;
        self.present(vc, animated: true, completion: nil)
    }
    
    //Peek delegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else {
                return nil }
        
        guard let detailViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "SingleFreebieID") as?
            SingleFreebieViewController else { return nil }
        
        if(self.restorationIdentifier == "1")
        {
            detailViewController.selectedFreebie = (self.freebiesByCat[Categories[indexPath.section]]?[indexPath.row])!
        }
        
        if(self.restorationIdentifier == "2")
        {
            detailViewController.selectedFreebie = self.freebies[indexPath.row]
        }
        
        if(self.restorationIdentifier == "3")
        {
            detailViewController.selectedFreebie = self.myFreebies[indexPath.row]
        }
        
        detailViewController.preferredContentSize = CGSize(width: 0.0, height: 600)
        
        previewingContext.sourceRect = cell.frame
        
        return detailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        show(viewControllerToCommit, sender: self)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColor.black
        header.textLabel?.textColor = UIColor.white
        header.alpha = 0.5
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if(self.restorationIdentifier == "1")
        {
            return Categories.count
        }
        if(self.restorationIdentifier == "2")
        {
            return 1
        }
        if(self.restorationIdentifier == "3")
        {
            return 1
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(self.restorationIdentifier == "1")
        {
            if let freebies = self.freebiesByCat[Categories[section]]
            {
                if freebies.count > 0
                {
                    return Categories[section]
                }
                else
                {
                    return ""
                }
            }
            else
            {
                return ""
            }
            
        }
        if(self.restorationIdentifier == "2")
        {
            return ""
        }
        if(self.restorationIdentifier == "3")
        {
            return ""
        }
        
        return ""
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.restorationIdentifier == "1")
        {
            if let freebies = self.freebiesByCat[Categories[section]]
            {
                return freebies.count
            }
            else
            {
                return 0
            }
        }
        
        if(self.restorationIdentifier == "2")
        {
            return self.freebies.count
        }
        
        if(self.restorationIdentifier == "3")
        {
            return self.myFreebies.count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FreebieCell", for: indexPath) as! FreebieTableViewCell
        
        var freebie : Freebie!
        
        if(self.restorationIdentifier == "1")
        {
            freebie = (self.freebiesByCat[Categories[indexPath.section]]?[indexPath.row])!
        }
        
        if(self.restorationIdentifier == "2")
        {
            freebie = self.freebies[indexPath.row]
        }
        
        if(self.restorationIdentifier == "3")
        {
            freebie = self.myFreebies[indexPath.row]
        }
        
        
        cell.TitleLbl.text = freebie?.title
        cell.PlaceLbl.text = freebie?.place
        cell.thumbsUpCnt.text = String(describing: freebie!.thumbsUp)
        cell.thumbsDownCnt.text = String(describing: freebie!.thumbsDown)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if(self.restorationIdentifier == "1")
        {
            selectedFreebie = self.freebiesByCat[Categories[indexPath.section]]?[indexPath.row]
            self.performSegue(withIdentifier: "singleFreebieSegue", sender: self)
        }
        
        if(self.restorationIdentifier == "2")
        {
            selectedFreebie = self.freebies[indexPath.row]
            self.performSegue(withIdentifier: "singleFreebieSegue", sender: self)
        }
        
        if(self.restorationIdentifier == "3")
        {
            selectedFreebie = self.myFreebies[indexPath.row]
            self.performSegue(withIdentifier: "postSegue", sender: self)
        }
    }
    
    //Methods
    
    func loadList(notification: NSNotification){
        self.loadData()
    }
    
    func refresh(sender:AnyObject)
    {
        self.loadData()
        self.refreshControl?.endRefreshing()
    }
    
    func loadData()
    {
        ref = FIRDatabase.database().reference()
        
        ref.child("Freebies").observeSingleEvent(of: .value, with: { (snapshot) in
            
            SignedInUser.sharedInstance.messages = snapshot.value as? [String: Any]
            
            if((SignedInUser.sharedInstance.messages?.count)! > 1)
            {
                self.freebies = []
                self.myFreebies = []
                for msg in SignedInUser.sharedInstance.messages!
                {
                    if(msg.key != "STATIC")
                    {
                        var message = msg.value as! [String: Any]
                        
                        let ctds = message["CTDS"] as! String
                        let hours = Calendar.current.dateComponents([.hour], from: ctds.date!, to: Date()).hour
                        
                        if(hours! > 1)
                        {
                            message["Active"] = 0
                            self.ref.child("Freebies/\(msg.key)/Active").setValue(0)
                        }
                        
                        if(message["Active"] as! Int == 1)
                        {
                            let temp = Freebie(id: msg.key, owner: message["Owner"]! as! String, title: message["Title"]! as! String, place: message["Place"]! as! String, description: message["Description"]! as! String, category: message["Category"]! as! String, thumbsup: message["thumbsUp"]! as! Int, thumbsdown: message["thumbsDown"]! as! Int, lat: message["latitude"]! as! Double, long: message["longitude"]! as! Double, lks: message["likes"] as! String, dlks: message["disLikes"] as! String, ctds: ctds)
                            self.freebies.append(temp)
                            if(SignedInUser.sharedInstance.userName! == temp.owner)
                            {
                                self.myFreebies.append(temp)
                            }
                        }
                    }
                }
            
                if(self.restorationIdentifier == "1")
                {
                    self.freebies.sort(by: self.sortbyThumbsUp)
                }
                
                if(self.restorationIdentifier == "2")
                {
                    self.freebies.sort(by: self.sortbyTimeStamp)
                }
                
                if(self.restorationIdentifier == "3")
                {
                    self.myFreebies.sort(by: self.sortbyTimeStamp)
                }
                
                self.generateFreebieCategories(freebies: self.freebies)
                
                self.tableView.reloadData()
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func generateFreebieCategories(freebies : [Freebie])
    {
        self.freebiesByCat.removeAll()
        
        for cat in self.Categories
        {
            for freebie in freebies
            {
                if freebie.category == cat
                {
                    if self.freebiesByCat[cat] == nil
                    {
                        self.freebiesByCat[cat] = []
                    }
                    
                    self.freebiesByCat[cat]?.append(freebie)
                }
            }
        }
    }
    
    func sortbyThumbsUp(a:Freebie, b:Freebie) -> Bool
    {
        return a.thumbsUp > b.thumbsUp
    }
    
    func sortbyTimeStamp(a:Freebie, b:Freebie) -> Bool
    {
        return a.CTDS > b.CTDS
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destController: SingleFreebieViewController = segue.destination as? SingleFreebieViewController
        {
            destController.selectedFreebie = self.selectedFreebie
        }
        
        if let destController: FreebieViewController = segue.destination as? FreebieViewController
        {
            if (self.selectedFreebie != nil)
            {
                destController.editFreebie = self.selectedFreebie
            }
        }
    }
 

}
