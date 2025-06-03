namespace EventEmitter {
    /**
     * `object` should be in either of the following forms:
     * ```
     * interface EventTypes {
     *   'event-with-parameters': any[]
     *   'event-with-example-handler': (...args: any[]) => void
     * }
     * ```
     */
    export type ValidEventTypes = string | symbol | object;

    export type EventNames<T extends ValidEventTypes> = T extends string | symbol
        ? T
        : keyof T;

    export type ArgumentMap<T extends object> = {
        [K in keyof T]: T[K] extends (...args: any[]) => void
        ? Parameters<T[K]>
        : T[K] extends any[]
        ? T[K]
        : any[];
    };

    export type EventListener<
        T extends ValidEventTypes,
        K extends EventNames<T>
        > = T extends string | symbol
        ? (...args: any[]) => void
        : (
            ...args: ArgumentMap<Exclude<T, string | symbol>>[Extract<K, keyof T>]
        ) => void;

    export type EventArgs<
        T extends ValidEventTypes,
        K extends EventNames<T>
        > = Parameters<EventListener<T, K>>;

    export interface ListenerData {
        fn: Function;
        context: any;
        once: boolean;
    }
}

export class EventEmitter<ListenEvents extends EventEmitter.ValidEventTypes = string | symbol, EmitEvents extends EventEmitter.ValidEventTypes = ListenEvents,  Context extends any = any> {
    private events = new Map<EventEmitter.EventNames<ListenEvents> | EventEmitter.EventNames<EmitEvents>, EventEmitter.ListenerData[]>()
    private _addListener<T extends EventEmitter.EventNames<ListenEvents>>(
        event: T,
        fn: EventEmitter.EventListener<ListenEvents, T>,
        context: Context = this as any,
        once: boolean = false
    ): this {
        if (typeof fn !== 'function') {
            throw new TypeError('The listener must be a function');
        }
        const listener = { fn, context, once }
        const allListeners = this.events.get(event)
        if(allListeners) {
            allListeners.push(listener)
        }
        else {
            this.events.set(event, [listener])
        }
        return this
    }
    addListener<T extends EventEmitter.EventNames<ListenEvents>>(
        event: T,
        fn: EventEmitter.EventListener<ListenEvents, T>,
        context?: Context
    ): this {
        return this._addListener(event, fn, context, false)
    }
    on = this.addListener
    once: typeof this.addListener = (event, fn, context?) => this._addListener(event, fn ,context, true)
    eventNames() {
        return Array.from(this.events.keys())
    }
    listeners<T extends EventEmitter.EventNames<ListenEvents>>(
        event: T
    ): Array<EventEmitter.EventListener<ListenEvents, T>> {
        return this.events.get(event)?.map(data => data.fn as any) || []
    }
    listenerCount(event: EventEmitter.EventNames<ListenEvents>) {
        return this.events.get(event)?.length || 0
    }
    /**
     * Remove the listeners of a given event.
     */
    removeListener<T extends EventEmitter.EventNames<ListenEvents>>(
        event: T,
        fn?: EventEmitter.EventListener<ListenEvents, T>,
        context?: Context,
        once?: boolean
    ): this {
        const allEvents = this.events.get(event)
        if(!allEvents) {
            return this
        }
        if(!fn && !context && once === undefined) {
            return this.removeAllListeners(event)
        }
        inplaceFilter(allEvents, listener => (!!fn && listener.fn !== fn) ||
            (!!context && listener.context !== context) ||
            (!!once && !listener.once)
        )
        if(allEvents.length == 0) {
            this.events.delete(event)
        }
        return this
    }
    off = this.removeListener

    /**
     * Remove all listeners, or those of the specified event.
     */
    removeAllListeners(event?: EventEmitter.EventNames<ListenEvents>): this {
        if(!event) {
            this.events.clear()
        }
        else {
            this.events.delete(event)
        }
        return this
    }

    /**
     * Calls each of the listeners registered for a given event.
     */
    emit<T extends EventEmitter.EventNames<EmitEvents>>(
        event: T,
        ...args: EventEmitter.EventArgs<EmitEvents, T>
    ): boolean {
        const listeners = this.events.get(event)
        if(!listeners) {
            return false
        }
        inplaceFilter(listeners, (listener) => {
            listener.fn?.apply(listener.context as any, args as any)
            return !listener.once
        })
        if(listeners.length == 0) {
            this.events.delete(event)
        }
        return true
    }
}
// #endregion

function inplaceFilter<T>(arr: Array<T>, cond: (val: T, i: number, a: Array<T>) => boolean) {
    let i = 0
    while(i < arr.length) {
        if(!cond(arr[i], i , arr)) {
            arr.splice(i, 1)
        }
        else {
            i++
        }
    }
}