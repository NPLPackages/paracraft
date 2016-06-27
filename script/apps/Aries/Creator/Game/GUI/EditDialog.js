angular.module('DialogItem', [])
.controller('DialogItemController', function ($scope, $http) {
    $scope.filename = (location.search.split('filename=')[1] || '').split('&')[0];

    $scope.actions = {
        accept: "",
        gotonext: "",
    };

    // json data source
    $scope.data = {
        title: "",
        gossips: [],
        triggers: [],
        quests:[],
    };

    $scope.itemTypes = ["item", "virtualitem"];
    $scope.buttonActions = ["gotonext", "accept", "goto item_name", "close"];
    $scope.avatarNames = ["player"];

    // add a new gossip
    $scope.addGossip = function () {
        var dialog = [];
        $scope.addDialogitem(dialog);
        $scope.data.gossips.push(dialog);
    };
    $scope.removeItem = function (fromItems, index, minCount) {
        if (fromItems.length > minCount)
            fromItems.splice(index, 1);
        else
            alert("at least " + minCount + " item must exist");
    };

    // add gossip item in a gossip
    $scope.addDialogitem = function (dialog) {
        dialog.push({
            name: "",
            avatar: { name: "", text: "" },
            content: "",
            buttons: [],
        });
    };

    $scope.addDialogButton = function (item) {
        if (item.buttons == null)
            item.buttons = [];
        item.buttons.push({});
    }

    // shuffel items up
    $scope.moveItemUp = function (items, index) {
        if (index > 0) {
            var tmp = items[index - 1];
            items[index - 1] = items[index];
            items[index] = tmp;
        }
    }

    $scope.addTrigger = function () {
        var trigger = {
            input: [],
            dialog: [],
            output: [],
        };
        $scope.addDialogitem(trigger.dialog);
        $scope.data.triggers.push(trigger);
    };

    $scope.addRuleitem = function (rule) {
        rule.push({
            name: "virtualitem",
            id: "",
            count: 1,
        });
    };

    $scope.reload = function () {
        var url = "ajax/open?file=script/apps/Aries/Creator/Game/GUI/EditDialog.page&filename="
            + encodeURIComponent($scope.filename) + "&action=get_dialog_file";
        $http.get(url).then(function (response) {
            $scope.data = response.data;
            $scope.last_message = "file loaded";
        });
    }

    $scope.save = function () {
        // var url = "ajax/open" + window.location.href.slice(window.location.href.indexOf('?')) + "&action=save_dialog_file";
        var url = "ajax/open?file=script/apps/Aries/Creator/Game/GUI/EditDialog.page&filename="
                    + encodeURIComponent($scope.filename) + "&action=save_dialog_file";

        $http.post(url, $scope.data).then(function (response) {
            if (response.data.success) {
                $scope.last_message = "file is successfully saved to " + response.data.filename;
            }
            else {
                $scope.last_message = "failed to saved to " + response.data.filename;
            }
        });
    }

    if ($scope.filename != null) {
        $scope.reload();
    }
    if (Page)
        Page.ShowSideBar(false);
});
