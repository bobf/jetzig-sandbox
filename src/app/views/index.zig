const jetzig = @import("jetzig");

pub fn index(request: *jetzig.http.StaticRequest, data: *jetzig.data.Data) anyerror!jetzig.views.View {
    var object = try data.object();
    try object.put("foo", data.string("hello"));
    return request.render(.ok);
}

pub fn get(id: []const u8, request: *jetzig.http.Request, data: *jetzig.data.Data) anyerror!jetzig.views.View {
    var object = try data.object();
    try object.put("fooz", data.string(id));
    return request.render(.ok);
}
