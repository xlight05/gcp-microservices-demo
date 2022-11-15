// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/grpc;
import ballerina/random;

type AdCategory record {|
    readonly string category;
    Ad[] ads;
|};

# Provides text advertisements based on the context of the given words.
@display {
    label: "Ads",
    id: "ads"
}
@grpc:Descriptor {value: DEMO_DESC}
service "AdService" on new grpc:Listener(9099) {

    private final readonly & table<AdCategory> key(category) adCategories;
    private final readonly & Ad[] allAds;
    private final int MAX_ADS_TO_SERVE = 2;

    function init() {
        self.adCategories = loadAds().cloneReadOnly();

        Ad[] ads = [];
        foreach var category in self.adCategories {
            ads.push(...category.ads);
        }
        self.allAds = ads.cloneReadOnly();
    }

    # Retrieves ads based on context provided in the request.
    #
    # + request - the request containing context
    # + return - the related/random ad response or else an error
    remote function GetAds(AdRequest request) returns AdResponse|error {
        Ad[] ads = [];
        foreach var category in request.context_keys {
            AdCategory? adCategory = self.adCategories[category];
            if adCategory !is () {
                ads.push(...adCategory.ads);
            }
        }

        if ads.length() == 0 {
            ads = check self.getRandomAds();
        }
        return {ads};
    }

    isolated function getRandomAds() returns Ad[]|error {
        Ad[] randomAds = [];
        foreach int i in 0 ..< self.MAX_ADS_TO_SERVE {
            int rIndex = check random:createIntInRange(0, self.allAds.length());
            randomAds.push(self.allAds[rIndex]);
        }
        return randomAds;
    }
}

isolated function loadAds() returns table<AdCategory> key(category) {
    Ad hairdryer = {
        redirect_url: "/product/2ZYFJ3GM2N",
        text: "Hairdryer for sale. 50% off."
    };
    Ad tankTop = {
        redirect_url: "/product/66VCHSJNUP",
        text: "Tank top for sale. 20% off."
    };
    Ad candleHolder = {
        redirect_url: "/product/0PUK6V6EV0",
        text: "Candle holder for sale. 30% off."
    };
    Ad bambooGlassJar = {
        redirect_url: "/product/9SIQT8TOJO",
        text: "Bamboo glass jar for sale. 10% off."
    };
    Ad watch = {
        redirect_url: "/product/1YMWWN1N4O",
        text: "Watch for sale. Buy one, get second kit for free"
    };
    Ad mug = {
        redirect_url: "/product/6E92ZMYYFZ",
        text: "Mug for sale. Buy two, get third one for free"
    };
    Ad loafers = {
        redirect_url: "/product/L9ECAV7KIM",
        text: "Loafers for sale. Buy one, get second one for free"
    };

    return table [
        {category: "clothing", ads: [tankTop]},
        {category: "accessories", ads: [watch]},
        {category: "footwear", ads: [loafers]},
        {category: "hair", ads: [hairdryer]},
        {category: "decor", ads: [candleHolder]},
        {category: "kitchen", ads: [bambooGlassJar, mug]}
    ];
}
