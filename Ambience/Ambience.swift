//
//  STAmbience.swift
//  STAmbience
//
//  Created by Tiago Mergulhão on 21/02/15.
//  Copyright (c) 2015 Tiago Mergulhão. All rights reserved.
//

import UIKit

public typealias Brightness = CGFloat
internal typealias BrightnessRange = (lower : Brightness, upper : Brightness)

public extension Notification.Name {
    public static let STAmbienceDidChange = Notification.Name("STAmbienceDidChangeNotification")
}

public class Ambience {
	
    public static var shared : Ambience = Ambience()
	
	public static var previousState : AmbienceState = .Regular
	public static var currentState : AmbienceState = .Regular {
        willSet {
            previousState = currentState
        }
        didSet {
            let notification : Notification = Notification(name: Notification.Name.STAmbienceDidChange, object: nil, userInfo: ["previousState" : previousState, "currentState": currentState])
            
            NotificationCenter.default.post(notification)
        }
	}
	internal var constraints : AmbienceConstraints = [
		.Invert(upper: 0.10),
		.Regular(lower: 0.05, upper: 0.95),
		.Contrast(lower: 0.90)
	] {
		didSet {
			checkBrightnessValue()
		}
	}
	
	internal func processConstraints (forBrightness brightness : Brightness) {

        let acceptableStates : AmbienceStates = constraints.filter{
            $0.rangeFunctor(brightness)
        }.map {
            $0.state
        }.reduce(AmbienceStates()) {
            (set : AmbienceStates, item : AmbienceState) -> AmbienceStates in
            return set.union([item])
        }

        if let firstState = acceptableStates.first, !acceptableStates.contains(Ambience.currentState) {
            Ambience.currentState = firstState
        }
	}
	internal func checkBrightnessValue () {
        processConstraints(forBrightness : UIScreen.main.brightness)
	}
    @objc public func brightnessDidChange (notification : NSNotification) {
		checkBrightnessValue()
	}
	
	public func insert ( _ constraint : AmbienceConstraint ) {
        var newSet = AmbienceConstraints()
        newSet.insert(constraint)
        newSet.formUnion(constraints)
        self.constraints = newSet
	}
	
	internal init () {
		
        NotificationCenter.default.addObserver(self,
            selector: #selector(brightnessDidChange),
			name: NSNotification.Name.UIScreenBrightnessDidChange,
			object: nil)
		
		checkBrightnessValue()
	}
	
	deinit {
        NotificationCenter.default.removeObserver(self)
	}
}

extension Ambience {
    public func insert ( _ constraints : AmbienceConstraints ) {
        constraints.forEach {
            [weak self] in
            self?.insert($0)
        }
    }
}