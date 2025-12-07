Bridge = {
    Debug = false  -- デバッグモードのグローバル設定
}

Bridge.frameWork =
    (GetResourceState("es_extended"):find("start") and "esx")
    or
    (GetResourceState("qb-core"):find("start") and "qb")

Bridge.core =
    (Bridge.frameWork == "esx" and exports["es_extended"]:getSharedObject())
    or
    (Bridge.frameWork == "qb" and exports["qb-core"]:GetCoreObject())

-- デバッグ用プリント関数
function Bridge.Debug(...)
    if Bridge.Debug then
        print(string.format("^3[DEBUG] %s^0", table.concat({...}, " ")))
    end
end

function Bridge.Error(...)
    if Bridge.Debug then
        print(string.format("^1[ERROR] %s^0", table.concat({...}, " ")))
    end
end