using System;
using System.Web;
using System.Web.SessionState;

public class AxpertHtmlAuthModule : IHttpModule
{
    private static readonly string[] ExcludedFolders =
    {
        "/ckeditor/", "/compiler/", "/packages/",
        "/bootstrap-session-timeout/", "/bootstrap-tokenfield/",
        "/gridstack", "/Linearicons/",
        "/CommonDir/", "/filemanager/", "/downloads/"
    };

    public void Init(HttpApplication application)
    {
        application.PostResolveRequestCache += OnPostMapRequestHandler;
    }

    private void OnPostMapRequestHandler(object sender, EventArgs e)
    {
        HttpApplication app = (HttpApplication)sender;
        HttpContext context = app.Context;

        string path = context.Request.Url.AbsolutePath;

        // Protect every .html/.htm file; third-party library folders are excluded
        if (!path.EndsWith(".html", StringComparison.OrdinalIgnoreCase) &&
            !path.EndsWith(".htm", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        foreach (string lib in ExcludedFolders)
        {
            if (path.IndexOf(lib, StringComparison.OrdinalIgnoreCase) >= 0)
                return;
        }

        // Replace IIS StaticFile handler with our handler.
        context.RemapHandler(new AxpertHtmlAuthHandler());
    }

    public void Dispose()
    {
    }
}


public class AxpertHtmlAuthHandler : IHttpHandler, IRequiresSessionState
{
    public bool IsReusable
    {
        get { return false; }
    }

    public void ProcessRequest(HttpContext context)
    {
        // Session should be available here because
        // this handler implements IRequiresSessionState.

        object project = context.Session["project"];
        object username = context.Session["username"];

        bool isLoggedIn =
            project != null &&
            !string.IsNullOrWhiteSpace(project.ToString()) &&
            username != null &&
            !string.IsNullOrWhiteSpace(username.ToString());

        if (!isLoggedIn)
        {
            context.Response.StatusCode = 401;
            context.Response.TrySkipIisCustomErrors = true;
            context.ApplicationInstance.CompleteRequest();
            return;
        }

        // Block direct browser navigation; iframe loads send Sec-Fetch-Dest: iframe.
        string dest = context.Request.Headers["Sec-Fetch-Dest"];
        bool direct = !string.IsNullOrEmpty(dest) && !string.Equals(dest, "iframe", StringComparison.OrdinalIgnoreCase);
        if (direct)
        {
            context.Response.StatusCode = 403;
            context.Response.TrySkipIisCustomErrors = true;
            context.ApplicationInstance.CompleteRequest();
            return;
        }

        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.Cache.SetNoStore();

        string filePath = context.Request.PhysicalPath;

        if (!System.IO.File.Exists(filePath))
        {
            context.Response.StatusCode = 404;
            context.Response.TrySkipIisCustomErrors = true;
            context.ApplicationInstance.CompleteRequest();
            return;
        }

        context.Response.ContentType = "text/html";

        context.Response.WriteFile(filePath);
    }
}
