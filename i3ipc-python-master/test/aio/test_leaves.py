from .ipctest import IpcTest

import pytest


class TestLeaves(IpcTest):
    @pytest.mark.asyncio
    async def test_workspace_leaves(self, i3):
        ws_name = await self.fresh_workspace()
        con1 = self.open_window()
        assert not (await i3.get_tree()).find_focused().is_floating()
        await self.command_checked(f'[id={con1}] floating enable')
        assert (await i3.get_tree()).find_focused().is_floating()
        self.open_window()
        self.open_window()

        tree = await i3.get_tree()
        ws = [w for w in tree.workspaces() if w.name == ws_name][0]

        assert (len(ws.leaves()) == 3)
