/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.lsp4j.services.json

import com.google.common.collect.Lists
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import org.eclipse.lsp4j.Message
import org.eclipse.lsp4j.RequestMessage
import org.eclipse.lsp4j.impl.CancelParamsImpl
import org.eclipse.lsp4j.impl.CodeActionParamsImpl
import org.eclipse.lsp4j.impl.CodeLensImpl
import org.eclipse.lsp4j.impl.CodeLensParamsImpl
import org.eclipse.lsp4j.impl.CommandImpl
import org.eclipse.lsp4j.impl.CompletionItemImpl
import org.eclipse.lsp4j.impl.CompletionListImpl
import org.eclipse.lsp4j.impl.DidChangeConfigurationParamsImpl
import org.eclipse.lsp4j.impl.DidChangeTextDocumentParamsImpl
import org.eclipse.lsp4j.impl.DidChangeWatchedFilesParamsImpl
import org.eclipse.lsp4j.impl.DidCloseTextDocumentParamsImpl
import org.eclipse.lsp4j.impl.DidOpenTextDocumentParamsImpl
import org.eclipse.lsp4j.impl.DidSaveTextDocumentParamsImpl
import org.eclipse.lsp4j.impl.DocumentFormattingParamsImpl
import org.eclipse.lsp4j.impl.DocumentHighlightImpl
import org.eclipse.lsp4j.impl.DocumentOnTypeFormattingParamsImpl
import org.eclipse.lsp4j.impl.DocumentRangeFormattingParamsImpl
import org.eclipse.lsp4j.impl.DocumentSymbolParamsImpl
import org.eclipse.lsp4j.impl.HoverImpl
import org.eclipse.lsp4j.impl.InitializeParamsImpl
import org.eclipse.lsp4j.impl.InitializeResultImpl
import org.eclipse.lsp4j.impl.LocationImpl
import org.eclipse.lsp4j.impl.MessageImpl
import org.eclipse.lsp4j.impl.MessageParamsImpl
import org.eclipse.lsp4j.impl.NotificationMessageImpl
import org.eclipse.lsp4j.impl.PublishDiagnosticsParamsImpl
import org.eclipse.lsp4j.impl.ReferenceParamsImpl
import org.eclipse.lsp4j.impl.RenameParamsImpl
import org.eclipse.lsp4j.impl.RequestMessageImpl
import org.eclipse.lsp4j.impl.ResponseErrorImpl
import org.eclipse.lsp4j.impl.ResponseMessageImpl
import org.eclipse.lsp4j.impl.ShowMessageRequestParamsImpl
import org.eclipse.lsp4j.impl.SignatureHelpImpl
import org.eclipse.lsp4j.impl.SymbolInformationImpl
import org.eclipse.lsp4j.impl.TextDocumentPositionParamsImpl
import org.eclipse.lsp4j.impl.TextEditImpl
import org.eclipse.lsp4j.impl.WorkspaceEditImpl
import org.eclipse.lsp4j.impl.WorkspaceSymbolParamsImpl
import org.eclipse.lsp4j.services.json.adapters.CollectionTypeAdapterFactory
import org.eclipse.lsp4j.services.json.adapters.EnumTypeAdapterFactory
import org.eclipse.lsp4j.services.json.adapters.MarkedStringTypeAdapterFactory
import org.eclipse.lsp4j.services.transport.client.MethodResolver
import org.eclipse.lsp4j.services.validation.IMessageValidator
import org.eclipse.lsp4j.services.validation.MessageIssue
import org.eclipse.lsp4j.services.validation.ReflectiveMessageValidator
import java.io.Reader
import java.io.StringReader
import java.io.StringWriter
import java.io.Writer
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors

class MessageJsonHandler {
	
	static val REQUEST_PARAM_TYPES = #{
		org.eclipse.lsp4j.services.transport.MessageMethods.INITIALIZE -> InitializeParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_COMPLETION -> TextDocumentPositionParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.RESOLVE_COMPLETION -> CompletionItemImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_HOVER -> TextDocumentPositionParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_SIGNATURE_HELP -> TextDocumentPositionParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_DEFINITION -> TextDocumentPositionParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_HIGHLIGHT -> TextDocumentPositionParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_REFERENCES -> ReferenceParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_SYMBOL -> DocumentSymbolParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.WORKSPACE_SYMBOL -> WorkspaceSymbolParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_CODE_ACTION -> CodeActionParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_CODE_LENS -> CodeLensParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.RESOLVE_CODE_LENS -> CodeLensImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_FORMATTING -> DocumentFormattingParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_RANGE_FORMATTING -> DocumentRangeFormattingParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_TYPE_FORMATTING -> DocumentOnTypeFormattingParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_RENAME -> RenameParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.SHOW_MESSAGE_REQUEST -> ShowMessageRequestParamsImpl
	}
	
	static val RESPONSE_RESULT_TYPES = #{
		org.eclipse.lsp4j.services.transport.MessageMethods.INITIALIZE -> InitializeResultImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_COMPLETION -> CompletionListImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.RESOLVE_COMPLETION -> CompletionItemImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_HOVER -> HoverImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_SIGNATURE_HELP -> SignatureHelpImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_DEFINITION -> LocationImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_HIGHLIGHT -> DocumentHighlightImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_REFERENCES -> LocationImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_SYMBOL -> SymbolInformationImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.WORKSPACE_SYMBOL -> SymbolInformationImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_CODE_ACTION -> CommandImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_CODE_LENS -> CodeLensImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.RESOLVE_CODE_LENS -> CodeLensImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_FORMATTING -> TextEditImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_RANGE_FORMATTING -> TextEditImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_TYPE_FORMATTING -> TextEditImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DOC_RENAME -> WorkspaceEditImpl
	}
	
	static val NOTIFICATION_PARAM_TYPES = #{
		org.eclipse.lsp4j.services.transport.MessageMethods.SHOW_DIAGNOSTICS -> PublishDiagnosticsParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DID_CHANGE_CONF -> DidChangeConfigurationParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DID_OPEN_DOC -> DidOpenTextDocumentParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DID_CHANGE_DOC -> DidChangeTextDocumentParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DID_CLOSE_DOC -> DidCloseTextDocumentParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DID_CHANGE_FILES -> DidChangeWatchedFilesParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.DID_SAVE_DOC -> DidSaveTextDocumentParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.SHOW_MESSAGE -> MessageParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.LOG_MESSAGE -> MessageParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.SHOW_MESSAGE_REQUEST -> ShowMessageRequestParamsImpl,
		org.eclipse.lsp4j.services.transport.MessageMethods.CANCEL -> CancelParamsImpl
	}
	
	val jsonParser = new JsonParser
	val Gson gson
	val IMessageValidator messageValidator = new ReflectiveMessageValidator
	
	@Accessors(PUBLIC_SETTER)
    MethodResolver methodResolver
	
	@Accessors(PUBLIC_SETTER)
	var boolean validateMessages = true
	
	new() {
		this(defaultGsonBuilder.create)
	}
	
	new(Gson gson) {
		this.gson = gson
	}
    
	def static GsonBuilder getDefaultGsonBuilder() {
	    new GsonBuilder()
	    	.registerTypeAdapterFactory(new CollectionTypeAdapterFactory)
            .registerTypeAdapterFactory(new EnumTypeAdapterFactory)
            .registerTypeAdapterFactory(new MarkedStringTypeAdapterFactory)
	}
	
	@Deprecated
	def void setResponseMethodResolver((String)=>String responseMethodResolver) {
	    methodResolver = if (responseMethodResolver === null) null else [responseMethodResolver.apply(it)]
	}
	
	def Message parseMessage(CharSequence input) {
		parseMessage(new StringReader(input.toString))
	}
	
	def Message parseMessage(Reader input) {
		val json = jsonParser.parse(input).asJsonObject
		val idElement = json.get('id')
		val methodElement = json.get('method')
		var MessageImpl result
		if (idElement !== null && methodElement !== null)
			result = parseRequest(json, idElement.asString, methodElement.asString)
		else if (idElement !== null && (json.get('result') !== null || json.get('error') !== null))
			result = parseResponse(json, idElement.asString)
		else if (methodElement !== null)
			result = parseNotification(json, methodElement.asString)
		else
			result = new MessageImpl
		result.jsonrpc = json.get('jsonrpc')?.asString
		if (validateMessages) {
			val issues = messageValidator.validate(result)
			if (!issues.empty)
				throw new InvalidMessageException(issuesToString(result, json, issues), idElement?.asString, null, json)
		}
		return result
	}
	
	protected def RequestMessageImpl parseRequest(JsonObject json, String requestId, String method) {
		try {
			val result = new RequestMessageImpl
			result.id = requestId
			result.method = method
			val params = json.get('params')?.asJsonObject
			if (params !== null) {
				val paramType = REQUEST_PARAM_TYPES.get(method)
				result.params = gson.fromJson(params, paramType ?: Object)
			}
			return result
		} catch (Exception e) {
			throw new InvalidMessageException("Could not parse request: " + e.message, requestId, e, json)
		}
	}
	
	protected def ResponseMessageImpl parseResponse(JsonObject json, String responseId) {
		if (methodResolver === null)
			throw new IllegalStateException("Response methods are not accepted.")
		try {
			val result = new ResponseMessageImpl
			result.id = responseId
			val resultElem = json.get('result')
			if (resultElem !== null) {
				val method = methodResolver.resolveMethod(responseId)
				if (method !== null) {
					val resultType = RESPONSE_RESULT_TYPES.get(method)
					if (resultType !== null) {
						if (resultElem.isJsonArray) {
							val arrayElem = resultElem.asJsonArray
							val list = Lists.newArrayListWithExpectedSize(arrayElem.size)
							for (e : arrayElem) {
								list += gson.fromJson(e, resultType)
							}
							result.result = list
						} else {
							result.result = gson.fromJson(resultElem, resultType)
						}
					} else {
						result.result = gson.fromJson(resultElem, Object)
					}
				}
			} else {
				val error = json.get('error')?.asJsonObject
				if (error !== null)
					result.error = gson.fromJson(error, ResponseErrorImpl)
			}
			return result
		} catch (Exception e) {
			throw new InvalidMessageException("Could not parse response: " + e.message, responseId, e, json)
		}
	}
	
	protected def NotificationMessageImpl parseNotification(JsonObject json, String method) {
		try {
			val result = new NotificationMessageImpl
			result.method = method
			val params = json.get('params')?.asJsonObject
			if (params !== null) {
				val paramType = NOTIFICATION_PARAM_TYPES.get(method)
				result.params = gson.fromJson(params, paramType ?: Object)
			}
			return result
		} catch (Exception e) {
			throw new InvalidMessageException("Could not parse notification: " + e.message, null, e, json)
		}
	}
	
	def String serialize(Message message) {
		val writer = new StringWriter
		serialize(message, writer)
		return writer.toString
	}
	
	def void serialize(Message message, Writer output) {
		if (validateMessages) {
			val issues = messageValidator.validate(message)
			if (!issues.empty)
				throw new org.eclipse.lsp4j.services.transport.InvalidMessageException(issuesToString(message, null, issues),
						if (message instanceof RequestMessage) message.id)
		}
		gson.toJson(message, output)
	}
	
	private def String issuesToString(Message message, JsonObject json, List<MessageIssue> issues) '''
		«FOR issue : issues»
			Error: «issue.text»
		«ENDFOR»
		The message was:
			«json ?: message»
	'''
	
}