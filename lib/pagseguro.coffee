req = require('request');

xml2js = require('xml2js');
xmlBuilder = new xml2js.Builder();

class pagseguro
    constructor: (@email, @token) ->
        this.obj = new Object
        this.obj['currency'] = 'BRL';
        this.xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        return this
        
    currency: (cur) ->
        this.obj['currency'] = cur;
        return this;
        
    reference: (ref) ->
        this.obj['reference'] = ref;
        return this;
        
    addItem: (item) ->
        if !this.obj['items']
          this.obj['items'] = new Array;
        
        this.obj.items.push({
          item: item
        });
        return this;
        
    buyer: (obj) ->
        this.obj['sender'] = new Object;
        if obj.name
          this.obj.sender['name'] = obj.name
        if obj.email
          this.obj.sender['email'] = obj.email

        this.obj.sender['phone'] = new Object;
        if obj.phoneAreaCode
          this.obj.sender.phone['areaCode'] = obj.phoneAreaCode
        if obj.phoneNumber
          this.obj.sender.phone['number'] = obj.phoneNumber
        return this;
        
    shipping: (obj) ->
        this.obj['shipping'] = new Object;
        if obj.type
          this.obj.shipping['type'] = obj.type

        this.obj.shipping['address'] = new Object;
        if obj.street
          this.obj.shipping.address['street'] = obj.street
        if obj.number
          this.obj.shipping.address['number'] = obj.number
        if obj.complement 
          this.obj.shipping.address['complement'] = obj.complement;
        if obj.district
          this.obj.shipping.address['district'] = obj.district;
        if obj.postalCode
          this.obj.shipping.address['postalCode'] = obj.postalCode;
        if obj.city
          this.obj.shipping.address['city'] = obj.city;
        if obj.state
          this.obj.shipping.address['state'] = obj.state;
        if obj.country
          this.obj.shipping.address['country'] = obj.country;
        return this;

    ###
    Configura as URLs de retorno e de notificação por pagamento
    ###
    setRedirectURL: (url) ->
        this.obj.redirectURL = url;
        return this;

    setNotificationURL: (url) ->
        this.obj.notificationURL = url;
        return this;

    send: (callback) ->
        options = {
            uri: "https://ws.pagseguro.uol.com.br/v2/checkout?email=" + this.email + "&token=" + this.token,
            method: 'POST',
            headers: {
                'Content-Type': 'application/xml; charset=UTF-8'
            },
            body: this.xml + xmlBuilder.buildObject({
                checkout: this.obj
            })
        };
        
        return req(options, (err, res, body) ->

            if err
              return callback(err)

            if res.statusCode != 200
              return xml2js.parseString body, (err, result) ->
                return callback(err) if err

                errCode = result.errors.error[0].code[0];
                errMsg = result.errors.error[0].message[0];
                callback(new Error('Pagseguro ' + errCode + ': '+ errMsg));

            xml2js.parseString body, (err, result) ->
              return callback(err) if err

              code = result.checkout.code[0];
              date = new Date(result.checkout.date[0]);

              callback(null, {code: code, date: date, url: "https://pagseguro.uol.com.br/v2/checkout/payment.html?code=" + code});
        );

module.exports = pagseguro;