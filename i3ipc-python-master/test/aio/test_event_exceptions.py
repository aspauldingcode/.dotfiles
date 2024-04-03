from .ipctest import IpcTest

import pytest
import asyncio


class HandlerException(Exception):
    pass


class TestEventExceptions(IpcTest):
    def exception_throwing_handler(self, i3, e):
        raise HandlerException()

    @pytest.mark.asyncio
    async def test_event_exceptions(self, i3):
        i3.on('tick', self.exception_throwing_handler)

        asyncio.ensure_future(i3.send_tick())

        with pytest.raises(HandlerException):
            await i3.main()
