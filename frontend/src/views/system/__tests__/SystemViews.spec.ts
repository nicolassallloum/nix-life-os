import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'
import { RouterLinkStub } from '@vue/test-utils'
import ComingSoonView from '../ComingSoonView.vue'
import ApplicationDownView from '../ApplicationDownView.vue'

describe('system status views', () => {
  it('renders the coming soon state without external image assets', () => {
    const wrapper = mount(ComingSoonView, {
      global: { stubs: { RouterLink: RouterLinkStub } },
    })

    expect(wrapper.get('h1').text()).toBe('Coming soon')
    expect(wrapper.find('img').exists()).toBe(false)
    expect(wrapper.getComponent(RouterLinkStub).props('to')).toBe('/')
  })

  it('renders the unavailable state and exposes retry navigation', async () => {
    const reload = vi.fn()
    Object.defineProperty(window, 'location', {
      configurable: true,
      value: { ...window.location, reload },
    })

    const wrapper = mount(ApplicationDownView, {
      global: { stubs: { RouterLink: RouterLinkStub } },
    })

    expect(wrapper.get('h1').text()).toBe('Temporarily unavailable')
    await wrapper.get('button').trigger('click')
    expect(reload).toHaveBeenCalledOnce()
  })
})
