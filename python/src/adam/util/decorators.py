from dataclasses import dataclass
from functools import cached_property, wraps
from typing import Any, Callable, ParamSpec, Type, TypeVar
from .util import get_class_attribute

P = ParamSpec("P")
T = TypeVar("T")


def freeze(cls: Type[T]) -> Type[T]:
    """
    A class decorator to prevent modifications to class instances after
    initialization.

    Once an instance of the class is created, its attributes cannot be
    modified or deleted. This is achieved by overriding the `__setattr__`
    and `__delattr__` methods to raise an `AttributeError` if any modification
    or deletion is attempted after the instance has been initialized.
    """

    original_init = cls.__init__

    def __init__(self, *args, **kwargs):
        self.__frozen__ = False
        original_init(self, *args, **kwargs)
        if not self.__frozen__:
            self.__frozen__ = True

    def __setattr__(self, key, value):
        if getattr(self, "__frozen__", False):
            class_name = self.__class__.__name__
            raise AttributeError(f"{class_name!r} is frozen")
        super(cls, self).__setattr__(key, value)

    def __delattr__(self, item):
        if getattr(self, "__frozen__", False):
            class_name = self.__class__.__name__
            raise AttributeError(f"{class_name!r} is frozen")
        super(cls, self).__delattr__(item)

    cls.__init__ = __init__
    cls.__setattr__ = __setattr__
    cls.__delattr__ = __delattr__

    return cls


def cached_properties(cls: Type[T]) -> Type[T]:
    """
    A class decorator to converts all properties into cached properties.
    """

    for name, attr in list(cls.__dict__.items()):
        if isinstance(attr, property):
            prop = cached_property(attr.fget)
            prop.__set_name__(cls, name)
            setattr(cls, name, prop)

    return cls


def key_comparable(cls: Type[T]) -> Type[T]:
    """
    A class decorator that adds __eq__ and __hash__ methods based on __key__.
    """

    def __eq__(self, other):
        if isinstance(other, type(self)):
            return self.__key__() == other.__key__()

        return False

    def __hash__(self):
        return hash(self.__key__())

    cls.__eq__ = __eq__
    cls.__hash__ = __hash__

    return cls


def fancy_dataclass(
    cls: Type[T] | None = None,
    /, *,
    init: bool = True,
    repr: bool = True,
    eq: bool = True,
    order: bool = False,
    unsafe_hash: bool = False,
    frozen: bool = False,
    match_args=True,
    kw_only: bool = False,
    slots: bool = False,
    cache: bool = True
) -> Callable[[Type[T]], Type[T]] | Type[T]:
    """
    A decorator for creating data classes with additional features.

    This decorator extends the functionality of the standard dataclass
    decorator by adding an optional caching mechanism for frozen classes
    and a custom freeze implementation.

    Warning: Not compatible with standard frozen dataclasses.

    Extra Parameters:
        cache (bool): If True, adds caching for properties. Defaults to True.
    """

    @wraps(cls)
    def decorator(cls: Type[T]) -> Type[T]:
        cls = dataclass(
            cls,
            init=init,
            repr=repr,
            eq=eq,
            order=order,
            unsafe_hash=unsafe_hash,
            frozen=False,
            match_args=match_args,
            kw_only=kw_only,
            slots=slots
        )

        if frozen:
            cls = freeze(cls)

        if cache and frozen:
            cls = cached_properties(cls)
        elif cache:
            raise ValueError("Cache not supported for non-frozen class.")

        if get_class_attribute(cls, "__key__"):
            cls = key_comparable(cls)

        return cls

    return decorator(cls) if cls else decorator
