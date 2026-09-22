/* Remmina secret plugin that wins init_order over glibsecret and reports
 * the secret service unavailable so passwords stay in the .remmina file
 * (3DES via remmina.pref secret). Stops the Login keyring unlock prompt. */
#include <remmina/plugin.h>

static gboolean nosecret_init(RemminaSecretPlugin *plugin)
{
  (void)plugin;
  return TRUE;
}

static gboolean nosecret_available(RemminaSecretPlugin *plugin)
{
  (void)plugin;
  return FALSE;
}

static void nosecret_store(
    RemminaSecretPlugin *plugin,
    RemminaFile *file,
    const gchar *key,
    const gchar *password
)
{
  (void)plugin;
  (void)file;
  (void)key;
  (void)password;
}

static gchar *nosecret_get(RemminaSecretPlugin *plugin, RemminaFile *file, const gchar *key)
{
  (void)plugin;
  (void)file;
  (void)key;
  return NULL;
}

static void nosecret_delete(RemminaSecretPlugin *plugin, RemminaFile *file, const gchar *key)
{
  (void)plugin;
  (void)file;
  (void)key;
}

static RemminaSecretPlugin remmina_plugin_nosecret = {
    .type = REMMINA_PLUGIN_TYPE_SECRET,
    .name = "nosecret",
    .description = "Disable libsecret / gnome-keyring",
    .domain = NULL,
    .version = "1",
    .init_order = 0,
    .init = nosecret_init,
    .is_service_available = nosecret_available,
    .store_password = nosecret_store,
    .get_password = nosecret_get,
    .delete_password = nosecret_delete,
};

G_MODULE_EXPORT gboolean remmina_plugin_entry(RemminaPluginService *service)
{
  return service->register_plugin((RemminaPlugin *)&remmina_plugin_nosecret);
}
