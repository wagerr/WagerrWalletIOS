//
//  EventSliderCell.swift
//  breadwallet
//
//  Created by MIP
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit
import BRCore

enum LegButtonMode {
    case add
    case remove
    case hidden
}

class EventSliderCellBase: EventDetailRowCell, UITextFieldDelegate {
    var betChoice : EventBetChoice?
    var cellDelegate: EventBetSliderDelegate?
    
    // MARK: - Accessors
    public var amount: String {
        get {
            return amountLabel.text ?? ""
        }
        set {
            amountLabel.text = newValue
        }
    }

    public var reward: String {
        get {
            return rewardLabel.text ?? ""
        }
        set {
            rewardLabel.text = newValue
        }
    }
  
    public var amountTextFrame : CGRect  {
        get {
            return amountLabel.frame
        }
    }
    
    internal var minBet : Float {
        return W.BetAmount.min
    }
    
    internal var maxBet : Float {
        return W.BetAmount.max
    }
    
    // MARK: Views
    internal let amountLabel = UITextField(frame: CGRect(x: 10.0, y: 10.0, width: 250.0, height: 35.0))
    internal let currencyLabel = UILabel(font: UIFont.customBody(size: 24.0))
    internal let rewardLabel = UILabel(font: UIFont.customBody(size: 16.0))
    internal let betSlider = BetSlider(frame: CGRect(x: 50.0, y: 10.0, width: 850.0, height: 35.0))
    internal let doBetButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    internal let doCancelButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    
    // MARK: - Init
    
    override func addSubviews() {
        super.addSubviews()
        container.addSubview(amountLabel)
        container.addSubview(currencyLabel)
        container.addSubview(rewardLabel)
        container.addSubview(betSlider)
        container.addSubview(doBetButton)
        container.addSubview(doCancelButton)
    }
    
    override func addConstraints() {
        rowHeight = CGFloat(120.0)
        super.addConstraints()
    
        amountLabel.constrain([
            amountLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            amountLabel.constraint(toTop: container, constant: C.padding[3])
        ])
        
        currencyLabel.constrain([
            currencyLabel.leadingAnchor.constraint(equalTo: amountLabel.trailingAnchor,constant: C.padding[1]),
            currencyLabel.topAnchor.constraint(equalTo: amountLabel.topAnchor)
        ])

        betSlider.constrain([
            betSlider.leadingAnchor.constraint(equalTo: container.leadingAnchor,constant: C.padding[3]),
            betSlider.trailingAnchor.constraint(equalTo: container.trailingAnchor,constant: -C.padding[3]),
            betSlider.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: C.padding[1]/2)
        ])

        rewardLabel.constrain([
            rewardLabel.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor),
            rewardLabel.topAnchor.constraint(equalTo: betSlider.bottomAnchor, constant: C.padding[1]/2)
        ])
        addButtonConstraints()
    }
    
    func addButtonConstraints() {
        doBetButton.constrain([
            doBetButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -C.padding[4]),
            doBetButton.topAnchor.constraint(equalTo: rewardLabel.bottomAnchor, constant: C.padding[1]),
            doBetButton.widthAnchor.constraint(equalToConstant: 44.0),
            doBetButton.heightAnchor.constraint(equalToConstant: 44.0)
        ])
        doCancelButton.constrain([
            doCancelButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: C.padding[4]),
            doCancelButton.topAnchor.constraint(equalTo: rewardLabel.bottomAnchor, constant: C.padding[1]),
            doCancelButton.widthAnchor.constraint(equalToConstant: 40.0),
            doCancelButton.heightAnchor.constraint(equalToConstant: 40.0)
        ])
    }
    
    override func setupStyle() {
        super.setupStyle()
        
        amountLabel.textColor = .primaryText
        let nMinBet = Int(minBet)
        self.amount = String.init( String(nMinBet))
        amountLabel.delegate = self
        amountLabel.returnKeyType = UIReturnKeyType.done
        amountLabel.keyboardType = UIKeyboardType.decimalPad
        amountLabel.font = UIFont.customBody(size: 24.0)
        addDoneButtonOnKeyboard()
        
        currencyLabel.text = Currencies.btc.code
        
        rewardLabel.textColor = .primaryText
        self.reward = S.EventDetails.potentialReward
        
        //setup slider
        self.betSlider.minimumValue = minBet;
        let balanceAmount = (Currencies.btc.state?.balance!.asUInt64)!/C.satoshis
        self.betSlider.maximumValue = min(maxBet, Float(balanceAmount) )
        self.betSlider.value = self.betSlider.minimumValue;
        self.betSlider.isContinuous = true
        betSlider.addTarget(self, action: #selector(self.onSliderChange(sender:)), for: .valueChanged)
        
        self.betSlider.minimumTrackTintColor = .colorSlider
        self.betSlider.maximumTrackTintColor = .gray
        let size : CGFloat = 24
        let highlightedStateOrangeColorImage = UIImage.createThumbImage(size: size, color: .orange)
        let defaultStateBlueColorImage = UIImage.createThumbImage(size: size, color: .colorSlider)
        self.betSlider.setThumbImage(highlightedStateOrangeColorImage, for: UIControlState.highlighted)
        self.betSlider.setThumbImage(defaultStateBlueColorImage, for: UIControlState.normal)

        doBetButton.image =  #imageLiteral(resourceName: "circleOk")  //.withRenderingMode(.alwaysTemplate)
        doCancelButton.image = #imageLiteral(resourceName: "circleCancel")  //.withRenderingMode(.alwaysTemplate)
        
        let tapActionOk = UITapGestureRecognizer(target: self, action:#selector(self.actionTappedOk(tapGestureRecognizer:)))
        doBetButton.isUserInteractionEnabled = true
        doBetButton.addGestureRecognizer(tapActionOk)
        
        let tapActionCancel = UITapGestureRecognizer(target: self, action:#selector(self.actionTappedCancel(tapGestureRecognizer:)))
        doCancelButton.isUserInteractionEnabled = true
        doCancelButton.addGestureRecognizer(tapActionCancel)
    }

    // MARK: - Tap actions
    @objc func actionTappedOk(tapGestureRecognizer: UITapGestureRecognizer) {
        textFieldDidEndEditing(amountLabel)
        self.cellDelegate?.didTapOk(choice: betChoice!, amount: Int(betSlider.value))
    }
    
    @objc func actionTappedCancel(tapGestureRecognizer: UITapGestureRecognizer) {
        self.cellDelegate?.didTapCancel()
    }

    @objc func onSliderChange(sender: UISlider)    {
        if betChoice == nil { return }
        self.amount = String(Int(sender.value))
        recalculateReward(amount: Int(sender.value))
     }
    
    func recalculateReward(amount: Int = -1)    {
        let sliderValue = ( amount == -1 ) ? Int(betSlider.value) : amount
        let potentialRewardData = betChoice?.potentialReward(stake: sliderValue)
        self.reward = String.init(format: "%@: %@ (%@)", S.EventDetails.potentialReward, potentialRewardData!.cryptoAmount, potentialRewardData!.fiatAmount)
    }
    
    // amount text field delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        adjustSlider()
        recalculateReward()
    }
    
    func adjustSlider() {
        let balanceAmount = (Currencies.btc.state?.balance!.asUInt64)!/C.satoshis
        let nMinBet = Int(minBet)
        let nMaxBet = min(maxBet, Float(balanceAmount) )
        let nAmount = Int(amount) ?? nMinBet

        if (nAmount <= nMinBet)  { amount = String(nMinBet) }
        if (Float(nAmount) > nMaxBet)  { amount = String(Int(nMaxBet)) }
        betSlider.setValue(Float(nAmount), animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.blackTranslucent

        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: S.RecoverWallet.done, style: UIBarButtonItemStyle.done, target: self, action: #selector(self.doneButtonAction))
        done.tintColor = .white

        let items = NSMutableArray()
        items.add(flexSpace)
        items.add(done)

        doneToolbar.items = items as! [UIBarButtonItem]
        doneToolbar.sizeToFit()

        self.amountLabel.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction()
    {
        self.amountLabel.resignFirstResponder()
    }
}


// custom bet slider
class BetSlider: UISlider {

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.trackRect(forBounds: bounds)
        rect.size.height = 4
        return rect
    }
}

//Creating an Image with rounded corners:
extension UIImage {
    class func createThumbImage(size: CGFloat, color: UIColor) -> UIImage {
        let layerFrame = CGRect(x: 0, y: 0, width: size, height: size)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = CGPath(ellipseIn: layerFrame.insetBy(dx: 1, dy: 1), transform: nil)
        shapeLayer.fillColor = color.cgColor
        shapeLayer.strokeColor = color.withAlphaComponent(0.65).cgColor

        let layer = CALayer.init()
        layer.frame = layerFrame
        layer.addSublayer(shapeLayer)
        return self.imageFromLayer(layer: layer)
    }
    class func imageFromLayer(layer: CALayer) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, UIScreen.main.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        guard let outputImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        UIGraphicsEndImageContext()
        return outputImage
    }
}

class EventSliderCell: EventSliderCellBase {

    internal let doAddLegButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    internal let addLegTitleLabel = UILabel(font: UIFont.customBody(size: 16.0))

    override func addSubviews() {
        super.addSubviews()
        container.addSubview(doAddLegButton)
        container.addSubview(addLegTitleLabel)
    }

    override func addConstraints() {
        super.addConstraints()
        
        addLegTitleLabel.constrain([
            addLegTitleLabel.leadingAnchor.constraint(equalTo: doAddLegButton.trailingAnchor, constant: C.padding[1]),
            addLegTitleLabel.topAnchor.constraint(equalTo: rewardLabel.bottomAnchor, constant: C.padding[2])
        ])
    }
    
    override func addButtonConstraints() {
        doBetButton.constrain([
            doBetButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -C.padding[8]),
            doBetButton.topAnchor.constraint(equalTo: rewardLabel.bottomAnchor, constant: C.padding[1]),
            doBetButton.widthAnchor.constraint(equalToConstant: 44.0),
            doBetButton.heightAnchor.constraint(equalToConstant: 44.0)
        ])
        doCancelButton.constrain([
            doCancelButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            doCancelButton.topAnchor.constraint(equalTo: rewardLabel.bottomAnchor, constant: C.padding[1]),
            doCancelButton.widthAnchor.constraint(equalToConstant: 40.0),
            doCancelButton.heightAnchor.constraint(equalToConstant: 40.0)
        ])
        doAddLegButton.constrain([
            doAddLegButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: C.padding[8]),
            doAddLegButton.topAnchor.constraint(equalTo: rewardLabel.bottomAnchor, constant: C.padding[1]),
            doAddLegButton.widthAnchor.constraint(equalToConstant: 44.0),
            doAddLegButton.heightAnchor.constraint(equalToConstant: 44.0)
        ])
        
    }

    override func setupStyle() {
        super.setupStyle()
        
        addLegTitleLabel.text = S.EventDetails.addLeg
        doAddLegButton.image =   #imageLiteral(resourceName: "plusAdd")  //.withRenderingMode(.alwaysTemplate)
                
        let tapActionAddLeg = UITapGestureRecognizer(target: self, action:#selector(self.actionTappedAddRemove(tapGestureRecognizer:)))
        doAddLegButton.isUserInteractionEnabled = true
        doAddLegButton.addGestureRecognizer(tapActionAddLeg)
        let tapActionAddLeg2 = UITapGestureRecognizer(target: self, action:#selector(self.actionTappedAddRemove(tapGestureRecognizer:)))
        addLegTitleLabel.isUserInteractionEnabled = true
        addLegTitleLabel.addGestureRecognizer(tapActionAddLeg2)
    }

    // MARK: - Tap actions
    @objc func actionTappedAddRemove(tapGestureRecognizer: UITapGestureRecognizer) {
        textFieldDidEndEditing(amountLabel)
        if addLegTitleLabel.text == S.EventDetails.addLeg  {
            self.cellDelegate?.didTapAddLeg(choice: betChoice!)
            updateLegButton(mode: .remove)
        }
        else    {
            self.cellDelegate?.didTapRemoveLeg(choice: betChoice!)
            updateLegButton(mode: .add)
        }
    }
    
    func updateLegButton( mode : LegButtonMode )  {
        switch mode {
            case .add:
                doAddLegButton.isHidden = false
                addLegTitleLabel.isHidden = false
                doAddLegButton.image = #imageLiteral(resourceName: "plusAdd")
                addLegTitleLabel.text = S.EventDetails.addLeg
            
            case .remove:
                doAddLegButton.isHidden = false
                addLegTitleLabel.isHidden = false
                doAddLegButton.image = #imageLiteral(resourceName: "minusDel")
                addLegTitleLabel.text = S.EventDetails.removeLeg
            
            case .hidden:
                doAddLegButton.isHidden = true
                addLegTitleLabel.isHidden = true
        }
    }
}
