var cs6 = function() {

  this.isCsound = function() {
    return typeof csoundApp != 'undefined';
  }

  this.log = function(msg) {
    if (this.isCsound()) {
      csoundApp.postMessage(msg);
    } else {
      console.log(msg);
    }
  }

  this.updateChannel = function(name, value) {
    if (this.isCsound()) {
      csoundApp.setControlChannel(name, value);
    } else {
      this.log("set " + name + " -> " + value);
    }
  }

  this.processMessage = function(msg) {
    // this.log(msg);
    // this.log(msg.data);

    var value = null;

    // massage data based on control type
    if (msg.type == "toggle") {
      value = msg.data;
    } else if (msg.type == "button") {
      value = msg.data.press;
    } else if (msg.type == "dial") {
      value = parseFloat(msg.data);
    } else if (msg.type == "slider") {
      value = parseFloat(msg.data.value);
    } else if (msg.type == "number") {
      value = parseFloat(msg.data);
    } else if (msg.type == "select") {
      value = msg.index;
    } else {
      this.log("WARNING: widget type " + msg.type + " is not yet supported.");
      return;
    }

    this.updateChannel(msg.target, value);
  }

  // used to replace default implementation of nx.globalLocalTransmit
  // - why is localObject always "dial1"?
  // - why is localParameter always "value"?
  this.csoundGlobalLocalTransmit = function(canvasID, localObject, localParameter, data) {
    // this.log(canvasID+"."+localObject+"."+localParameter+"."+data + "\ndata: ");
    // this.log(data);

    // get the control instance
    var $ctl = $("#"+canvasID);

    // encapsulate the control message to make it more self-describing:
    //  - type (of control)
    //  - target (channel for message, same as control ID)
    //  - index (if it is a select control)
    //  - data (from control)
    var msg = {
      type: null,
      target: $ctl.attr("id"),
      index: null,
      data: data
    };

    // get the nx control type to tag this message with
    msg.type = $ctl.attr("nx");
    if (msg.type == null) {
      // select (e.g.) uses a native HTML element
      msg.type = $ctl.prop("tagName").toLowerCase();
    }

    // for select controls, get the index of the selection
    msg.index = null;
    var idx = $ctl[0].selectedIndex;
    if (typeof idx != "undefined") {
      msg.index = idx;
    }

    // we're running in the context of nx, so "this" refers to nx
    this.cs6.processMessage(msg);
  }

  // required: call this inside nx.onload() as cs6.init()
  this.init = function() {
    if (this.isCsound()) {
      this.log("csound6 detected");
      nx.cs6 = this;
      nx.sendsTo("js");
      nx.globalLocalTransmit = this.csoundGlobalLocalTransmit;
    } else {
      this.log("csound6 not detected");
    }
  }

}

var cs6 = new cs6();
